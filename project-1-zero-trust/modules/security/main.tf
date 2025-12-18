locals {
  sg_tags = merge(
    var.tags,
    {
      Component = "network-security"
    }
  )
}

# ─────────────────────────────────────────────────────────────
# ALB / ATM Edge SG
# - Internet -> ALB on 443 only
# - No direct DB access (enforced on DB SG side)
# ─────────────────────────────────────────────────────────────
resource "aws_security_group" "alb_edge" {
  name        = "alb-edge-sg"
  description = "Internet-facing ALB / ATM / Online banking edge"
  vpc_id      = var.vpc_id

  ingress {
    description      = "HTTPS from Internet"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  # Allow outbound only to internal networks (will be further refined later)
  egress {
    description      = "To internal services"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["10.0.0.0/8"]
    ipv6_cidr_blocks = []
  }

  tags = merge(local.sg_tags, {
    Name = "sg-alb-edge"
    Tier = "edge"
  })
}

# ─────────────────────────────────────────────────────────────
# Core-Banking App SG
# - Only ALB/edge can call app over 443
# - App can call DB (5432) and logging tools (443)
# ─────────────────────────────────────────────────────────────
resource "aws_security_group" "core_app" {
  name        = "core-app-sg"
  description = "Core-banking app services"
  vpc_id      = var.vpc_id

  # Ingress only from ALB edge
  ingress {
    description     = "HTTPS from ALB / ATM edge"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_edge.id]
  }

  # Egress to DB over DB port (example: 5432 for PostgreSQL)
  egress {
    description = "App to Core DB on 5432"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # Egress to logging tools (HTTPS or API)
  egress {
    description = "App to logging tools (HTTPS)"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  tags = merge(local.sg_tags, {
    Name = "sg-core-app"
    Tier = "core-app"
  })
}

# ─────────────────────────────────────────────────────────────
# Core DB SG
# - Only reachable from core app on DB port
# - No direct Internet or ALB access
# ─────────────────────────────────────────────────────────────
resource "aws_security_group" "core_db" {
  name        = "core-db-sg"
  description = "Core banking database"
  vpc_id      = var.vpc_id

  ingress {
    description     = "DB traffic from core app only"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.core_app.id]
  }

  egress {
    description      = "DB outbound for patching and backups (restricted ranges only)"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = var.db_backup_cidrs
    ipv6_cidr_blocks = []
  }

  tags = merge(local.sg_tags, {
    Name = "sg-core-db"
    Tier = "core-db"
  })
}

# ─────────────────────────────────────────────────────────────
# Fraud / AML Analytics SG
# - Reads logs & event streams (e.g. 443/9092) from logging tier
# - No direct DB access
# ─────────────────────────────────────────────────────────────
resource "aws_security_group" "fraud_analytics" {
  name        = "fraud-analytics-sg"
  description = "Fraud / AML analytics tier"
  vpc_id      = var.vpc_id

  # Ingress from internal tools / pipelines (kept narrow here)
  ingress {
    description = "Internal analytics access"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"] # lab VPC only
  }

  # Egress to logging tools: HTTPS / API (443) and Kafka-like (9092) example
  egress {
    description = "Fraud analytics to logging APIs"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    description = "Fraud analytics to event streams (9092)"
    from_port   = 9092
    to_port     = 9092
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  tags = merge(local.sg_tags, {
    Name = "sg-fraud-analytics"
    Tier = "fraud-aml"
  })
}

# ─────────────────────────────────────────────────────────────
# Logging / Security Tools SG
# - Only app + fraud tiers can talk to logging
# - No Internet ingress
# ─────────────────────────────────────────────────────────────
resource "aws_security_group" "logging_tools" {
  name        = "logging-tools-sg"
  description = "Logging / SIEM / Security Lake collectors"
  vpc_id      = var.vpc_id

  # Ingress from core app and fraud analytics
  ingress {
    description     = "HTTPS / API from core app"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.core_app.id]
  }

  ingress {
    description     = "HTTPS / API from fraud analytics"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.fraud_analytics.id]
  }

  # Default egress to internal network (for sending logs out, agents, etc.)
  egress {
    description      = "Logging tools outbound"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["10.0.0.0/16"]
    ipv6_cidr_blocks = []
  }

  tags = merge(local.sg_tags, {
    Name = "sg-logging-tools"
    Tier = "logging"
  })
}

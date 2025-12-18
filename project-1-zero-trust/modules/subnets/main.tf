# Public subnets + route table (Internet-facing for LB / bastion)
resource "aws_subnet" "public" {
  for_each = {
    for idx, cidr in var.public_subnet_cidrs :
    idx => {
      cidr = cidr
      az   = var.azs[idx]
    }
  }

  vpc_id                  = var.vpc_id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = true

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-public-${each.value.az}"
      Tier = "public"
    }
  )
}

resource "aws_route_table" "public" {
  vpc_id = var.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = var.igw_id
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-public-rt"
    }
  )
}

resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# Private app subnets (no internet route by default)
resource "aws_subnet" "private_app" {
  for_each = {
    for idx, cidr in var.private_app_subnet_cidrs :
    idx => {
      cidr = cidr
      az   = var.azs[idx]
    }
  }

  vpc_id            = var.vpc_id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-app-${each.value.az}"
      Tier = "app"
    }
  )
}

# Private DB subnets
resource "aws_subnet" "private_db" {
  for_each = {
    for idx, cidr in var.private_db_subnet_cidrs :
    idx => {
      cidr = cidr
      az   = var.azs[idx]
    }
  }

  vpc_id            = var.vpc_id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-db-${each.value.az}"
      Tier = "db"
    }
  )
}

# Logging / security tools subnets
resource "aws_subnet" "logging" {
  for_each = {
    for idx, cidr in var.logging_subnet_cidrs :
    idx => {
      cidr = cidr
      az   = var.azs[idx]
    }
  }

  vpc_id            = var.vpc_id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-logging-${each.value.az}"
      Tier = "logging"
    }
  )
}

# ─────────────────────────────────────────────────────────────
# Private route tables per tier (micro-segmentation)
# - Core App     → app-only route table
# - Core DB/Fraud→ db-only route table
# - Logging      → logging-only route table
#   (no default route to Internet in any private tier)
# ─────────────────────────────────────────────────────────────

resource "aws_route_table" "private_app" {
  vpc_id = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-app-rt"
      Tier = "app"
    }
  )
}

resource "aws_route_table_association" "private_app" {
  for_each       = aws_subnet.private_app
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private_app.id
}

resource "aws_route_table" "private_db" {
  vpc_id = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-db-rt"
      Tier = "db-fraud-aml"
    }
  )
}

resource "aws_route_table_association" "private_db" {
  for_each       = aws_subnet.private_db
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private_db.id
}

resource "aws_route_table" "logging" {
  vpc_id = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-logging-rt"
      Tier = "logging-tools"
    }
  )
}

resource "aws_route_table_association" "logging" {
  for_each       = aws_subnet.logging
  subnet_id      = each.value.id
  route_table_id = aws_route_table.logging.id
}

# ─────────────────────────────────────────────────────────────
# Network ACL for DB subnets
# - Only allow DB traffic from inside the VPC (enforced to app tier by SG)
# - Acts as default-deny boundary to anything outside 10.0.0.0/16
# ─────────────────────────────────────────────────────────────
resource "aws_network_acl" "db" {
  vpc_id = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-db-nacl"
      Tier = "db"
    }
  )

  # Inbound: allow PostgreSQL (5432) from inside the VPC
  ingress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "10.0.0.0/16"
    from_port  = 5432
    to_port    = 5432
  }

  # Outbound: allow ephemeral responses back to app tier
  egress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "10.0.0.0/16"
    from_port  = 1024
    to_port    = 65535
  }
}

# Associate DB NACL with all DB subnets
resource "aws_network_acl_association" "db" {
  for_each = aws_subnet.private_db

  subnet_id      = each.value.id
  network_acl_id = aws_network_acl.db.id
}

# ─────────────────────────────────────────────────────────────
# Network ACL for Logging / Security subnets
# - Only app + fraud tiers (inside VPC) can reach logging
# - No path from Internet because:
#   * no 0.0.0.0/0 allow
#   * subnets are private and not routed to IGW
# ─────────────────────────────────────────────────────────────
resource "aws_network_acl" "logging" {
  vpc_id = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-logging-nacl"
      Tier = "logging"
    }
  )

  # Inbound: allow HTTPS from internal tiers (app, fraud, etc.) inside the VPC
  ingress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "10.0.0.0/16"
    from_port  = 443
    to_port    = 443
  }

  # Optional: allow event stream traffic (example Kafka-like 9092) from internal tiers
  ingress {
    rule_no    = 110
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "10.0.0.0/16"
    from_port  = 9092
    to_port    = 9092
  }

  # Outbound: allow logging tools to send data to internal services
  egress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "10.0.0.0/16"
    from_port  = 0
    to_port    = 65535
  }
}

# Associate Logging NACL with all logging subnets
resource "aws_network_acl_association" "logging" {
  for_each = aws_subnet.logging

  subnet_id      = each.value.id
  network_acl_id = aws_network_acl.logging.id
}

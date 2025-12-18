locals {
  nacl_tags = merge(var.tags, { Component = "network-nacls" })
}

# ─────────────────────────────────────────────────────────────
# DB SUBNET NACL
# - Only DB port + ephemeral within VPC
# - No other inbound allowed (default deny)
# ─────────────────────────────────────────────────────────────
resource "aws_network_acl" "db" {
  vpc_id = var.vpc_id

  tags = merge(local.nacl_tags, {
    Name = "nacl-db-tier"
    Tier = "core-db"
  })
}

resource "aws_network_acl_association" "db" {
  for_each       = toset(var.db_subnet_ids)
  subnet_id      = each.value
  network_acl_id = aws_network_acl.db.id
}

# Inbound: allow DB port 5432 from inside the VPC
# (SGs still restrict this to the core-app SG only)
resource "aws_network_acl_rule" "db_in_5432" {
  network_acl_id = aws_network_acl.db.id
  rule_number    = 100
  egress         = false
  protocol       = "6" # TCP
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr
  from_port      = 5432
  to_port        = 5432
}

# Inbound: allow ephemeral responses from VPC
resource "aws_network_acl_rule" "db_in_ephemeral" {
  network_acl_id = aws_network_acl.db.id
  rule_number    = 110
  egress         = false
  protocol       = "6"
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr
  from_port      = 1024
  to_port        = 65535
}

# Outbound: allow ephemeral traffic to VPC
resource "aws_network_acl_rule" "db_out_ephemeral" {
  network_acl_id = aws_network_acl.db.id
  rule_number    = 100
  egress         = true
  protocol       = "6"
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr
  from_port      = 1024
  to_port        = 65535
}

# ─────────────────────────────────────────────────────────────
# LOGGING / SECURITY TOOLS NACL
# - Only 443 + ephemeral from inside VPC
# - No Internet ingress (subnets are private + default deny)
# ─────────────────────────────────────────────────────────────
resource "aws_network_acl" "logging" {
  vpc_id = var.vpc_id

  tags = merge(local.nacl_tags, {
    Name = "nacl-logging-tier"
    Tier = "logging"
  })
}

resource "aws_network_acl_association" "logging" {
  for_each       = toset(var.logging_subnet_ids)
  subnet_id      = each.value
  network_acl_id = aws_network_acl.logging.id
}

# Inbound: HTTPS/API traffic from inside VPC only
resource "aws_network_acl_rule" "logging_in_443" {
  network_acl_id = aws_network_acl.logging.id
  rule_number    = 100
  egress         = false
  protocol       = "6"
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr
  from_port      = 443
  to_port        = 443
}

# Inbound: ephemeral responses
resource "aws_network_acl_rule" "logging_in_ephemeral" {
  network_acl_id = aws_network_acl.logging.id
  rule_number    = 110
  egress         = false
  protocol       = "6"
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr
  from_port      = 1024
  to_port        = 65535
}

# Outbound: allow to VPC (agents shipping logs, etc.)
resource "aws_network_acl_rule" "logging_out_ephemeral" {
  network_acl_id = aws_network_acl.logging.id
  rule_number    = 100
  egress         = true
  protocol       = "6"
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr
  from_port      = 0
  to_port        = 65535
}

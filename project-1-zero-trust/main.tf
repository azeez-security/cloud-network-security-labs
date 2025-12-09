# ─────────────────────────────────────────────────────────────
# Locals: naming + common tags (Tier-1 banking lab)
# ─────────────────────────────────────────────────────────────
locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    Owner       = "netsec-labs"
    ManagedBy   = "terraform"
    Sector      = "Tier1-Banking"
  }
}

# ─────────────────────────────────────────────────────────────
# Core VPC  (DNS support/hostnames enabled inside module)
# ─────────────────────────────────────────────────────────────
module "vpc" {
  source = "./modules/vpc"

  vpc_cidr     = var.vpc_cidr
  azs          = var.azs
  project_name = var.project_name
  environment  = var.environment

  tags = merge(local.common_tags, {
    Component = "network-core"
    Name      = "${local.name_prefix}-vpc"
  })
}

# ─────────────────────────────────────────────────────────────
# Subnets: core-banking + fraud-aml + logging (ATM reserved in CIDR)
# public_subnet_cidrs      → front-door (core/atm APIs)
# private_app_subnet_cidrs → core-banking app tier
# private_db_subnet_cidrs  → fraud-aml analytics tier
# logging_subnet_cidrs     → logging/forensics tooling
# ─────────────────────────────────────────────────────────────
module "subnets" {
  source = "./modules/subnets"

  vpc_id = module.vpc.vpc_id
  igw_id = module.vpc.igw_id
  azs    = var.azs

  public_subnet_cidrs      = var.public_subnet_cidrs
  private_app_subnet_cidrs = var.private_app_subnet_cidrs
  private_db_subnet_cidrs  = var.private_db_subnet_cidrs
  logging_subnet_cidrs     = var.logging_subnet_cidrs

  project_name = var.project_name
  environment  = var.environment

  tags = merge(local.common_tags, {
    Component = "network-subnets"
  })
}

# ─────────────────────────────────────────────────────────────
# Logging: VPC Flow Logs → CloudWatch (later replicated to forensics)
# ─────────────────────────────────────────────────────────────
module "logging" {
  source = "./modules/logging"

  vpc_id          = module.vpc.vpc_id
  log_bucket_name = "${local.name_prefix}-flow-logs" # if you also use S3 later

  tags = merge(local.common_tags, {
    Component = "network-logging"
  })
}

# ─────────────────────────────────────────────────────────────
# Security groups skeleton (to be hardened in later weeks)
# ─────────────────────────────────────────────────────────────
module "security" {
  source = "./modules/security"

  vpc_id             = module.vpc.vpc_id
  app_subnet_ids     = module.subnets.private_app_subnet_ids
  db_subnet_ids      = module.subnets.private_db_subnet_ids
  logging_subnet_ids = module.subnets.logging_subnet_ids

  tags = merge(local.common_tags, {
    Component = "network-security"
  })
}

locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    Owner       = "netsec-labs"
  }
}

# ── Core VPC ────────────────────────────────────────────────
module "vpc" {
  source       = "./modules/vpc"
  vpc_cidr     = var.vpc_cidr
  azs          = var.azs
  project_name = var.project_name
  environment  = var.environment
  tags         = local.common_tags
}

# ── Subnets (public, app, db, logging) ─────────────────────
module "subnets" {
  source                   = "./modules/subnets"
  vpc_id                   = module.vpc.vpc_id
  igw_id                   = module.vpc.igw_id
  azs                      = var.azs
  public_subnet_cidrs      = var.public_subnet_cidrs
  private_app_subnet_cidrs = var.private_app_subnet_cidrs
  private_db_subnet_cidrs  = var.private_db_subnet_cidrs
  logging_subnet_cidrs     = var.logging_subnet_cidrs
  project_name             = var.project_name
  environment              = var.environment
  tags                     = local.common_tags
}

# ── Logging (VPC Flow Logs to encrypted S3) ─────────────────
module "logging" {
  source          = "./modules/logging"
  vpc_id          = module.vpc.vpc_id
  log_bucket_name = "${var.project_name}-flow-logs-${var.environment}"
  tags            = local.common_tags
}

# ── Security groups skeleton (to be expanded later) ─────────
module "security" {
  source             = "./modules/security"
  vpc_id             = module.vpc.vpc_id
  app_subnet_ids     = module.subnets.private_app_subnet_ids
  db_subnet_ids      = module.subnets.private_db_subnet_ids
  logging_subnet_ids = module.subnets.logging_subnet_ids
  tags               = local.common_tags
}

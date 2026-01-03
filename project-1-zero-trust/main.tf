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

module "nacls" {
  source = "./modules/nacls"

  vpc_id             = module.vpc.vpc_id
  vpc_cidr           = var.vpc_cidr
  app_subnet_ids     = module.subnets.private_app_subnet_ids
  db_subnet_ids      = module.subnets.private_db_subnet_ids
  logging_subnet_ids = module.subnets.logging_subnet_ids

  tags = local.common_tags
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
  source             = "./modules/security"
  vpc_id             = module.vpc.vpc_id
  app_subnet_ids     = module.subnets.private_app_subnet_ids
  db_subnet_ids      = module.subnets.private_db_subnet_ids
  logging_subnet_ids = module.subnets.logging_subnet_ids

  db_backup_cidrs = ["10.0.240.0/24"] # example backup/ops network (TGW or separate VPC)

  tags = merge(local.common_tags, {
    Component = "network-security"
  })
}

data "aws_caller_identity" "current" {}

locals {
  default_tags = {
    Project     = "Project-1-Zero-Trust"
    Domain      = "FinOps"
    Environment = "SecurityLab"
    Owner       = data.aws_caller_identity.current.account_id
  }
}

module "forensics_vault" {
  source = "./modules/forensics"

  providers = {
    aws = aws.ca
  }

  bucket_name    = var.forensics_bucket_name
  kms_alias      = var.forensics_kms_alias
  classification = var.classification_tag
  retention      = var.retention_tag

  log_writer_role_arn   = aws_iam_role.forensics_log_writer.arn
  soc_reader_role_arn   = aws_iam_role.forensics_soc_reader.arn
  audit_reader_role_arn = aws_iam_role.forensics_audit_reader.arn
  break_glass_role_arn  = aws_iam_role.forensics_break_glass.arn

  tags = local.default_tags
}

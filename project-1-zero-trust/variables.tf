variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "Primary AWS region for Tier-1 banking lab (Project 1)."
}

variable "project_name" {
  type        = string
  default     = "cloud-bank-zero-trust"
  description = "Name prefix for all Tier-1 banking lab resources."
}

variable "environment" {
  type        = string
  default     = "lab"
  description = "Environment name (lab/dev/test/prod/dr)."
}

variable "vpc_cidr" {
  type        = string
  default     = "10.0.0.0/16"
  description = "Root CIDR for this region+environment VPC."
}

variable "azs" {
  type        = list(string)
  description = "AZs to span (1 public + 1 private per AZ)."
  default     = ["us-east-1a", "us-east-1b"]
}

# ─────────────────────────────────────────────────────────────
# Week-1 CIDR allocation per tier (core, fraud, logging)
# ATM + DR tiers are reserved in the strategy but not yet deployed
# ─────────────────────────────────────────────────────────────

# Public front-door subnets (ALB/API for core + ATM edge)
# Zone split: AZ-a = 10.0.0.0/24, AZ-b = 10.0.1.0/24
variable "public_subnet_cidrs" {
  type        = list(string)
  default     = ["10.0.0.0/24", "10.0.1.0/24"]
  description = "Public subnets (internet-facing ingress for core/ATM APIs)."
}

# Core-banking app tier (business logic, internal APIs)
# AZ-a = 10.0.10.0/24, AZ-b = 10.0.11.0/24
variable "private_app_subnet_cidrs" {
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
  description = "Private app subnets for core-banking services."
}

# Fraud & AML analytics tier (separate from core app tier)
# AZ-a = 10.0.20.0/24, AZ-b = 10.0.21.0/24
variable "private_db_subnet_cidrs" {
  type        = list(string)
  default     = ["10.0.20.0/24", "10.0.21.0/24"]
  description = "Private subnets representing fraud/AML analytics or DB tier."
}

# Logging / security tooling tier
# AZ-a = 10.0.200.0/24, AZ-b = 10.0.201.0/24
variable "logging_subnet_cidrs" {
  type        = list(string)
  default     = ["10.0.200.0/24", "10.0.201.0/24"]
  description = "Subnets for logging/security tooling and collectors."
}

variable "forensics_region" {
  type        = string
  description = "Region for forensic audit vault (Week 4)"
  default     = "ca-central-1"
}

variable "forensics_bucket_name" {
  type        = string
  description = "S3 bucket name for immutable forensic logs (must be globally unique)"
}

variable "forensics_kms_alias" {
  type        = string
  description = "KMS alias name for forensic CMK"
  default     = "alias/forensics-log-cmk"
}

variable "forensics_retention_days" {
  type        = number
  description = "CloudTrail retention in CloudWatch logs (days) for Week 4 evidence"
  default     = 365
}

variable "classification_tag" {
  type    = string
  default = "Forensic"
}

variable "retention_tag" {
  type    = string
  default = "7y"
}

variable "unencrypted_demo_bucket_name" {
  type        = string
  description = "Globally-unique bucket name used for the intentionally insecure demo"
  default     = ""
}

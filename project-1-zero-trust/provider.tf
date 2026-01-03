terraform {
  required_version = ">= 1.4.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Primary region (Week 1-3 resources)
provider "aws" {
  region = var.aws_region
}

# Forensics vault region (Week 4)
provider "aws" {
  alias  = "ca"
  region = var.forensics_region
}

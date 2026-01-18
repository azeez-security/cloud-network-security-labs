module "security_platform" {
  source = "../modules/security"

  project_name = "project-2-xdr-soar"

  enable_guardduty   = true
  enable_securityhub = true
  enable_detective   = true

  # NEW (SOAR)
  enable_soar               = true
  enable_soar_evidence_s3   = true
  soar_evidence_bucket_name = "project-2-xdr-soar-evidence-${data.aws_caller_identity.current.account_id}"

  securityhub_standards = [
    "aws-foundational-security-best-practices/v/1.0.0",
    "pci-dss/v/3.2.1"
  ]
}

data "aws_caller_identity" "current" {}

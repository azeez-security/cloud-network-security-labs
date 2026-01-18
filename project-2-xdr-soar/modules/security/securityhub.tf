########################################
# Security Hub – Core enablement
########################################

resource "aws_securityhub_account" "this" {
  count                    = var.enable_securityhub ? 1 : 0
  enable_default_standards = false
}

data "aws_region" "current" {}

########################################
# Standards – AWS FSBP, PCI, CIS, etc.
########################################

resource "aws_securityhub_standards_subscription" "this" {
  count = var.enable_securityhub ? length(var.securityhub_standards) : 0

  # Example input:
  # "aws-foundational-security-best-practices/v/1.0.0"
  # "pci-dss/v/3.2.1"
  standards_arn = "arn:aws:securityhub:${data.aws_region.current.name}::standards/${var.securityhub_standards[count.index]}"

  # Ensure Security Hub is enabled before subscribing standards
  depends_on = [aws_securityhub_account.this]
}

########################################
# Baseline XDR Insight – CRITICAL findings
# Provider-stable: use severity_label (not severity_normalized)
########################################

resource "aws_securityhub_insight" "critical_findings" {
  count = var.enable_securityhub ? 1 : 0

  name               = "${var.securityhub_insight_prefix}-critical-findings"
  group_by_attribute = "ResourceId"

  filters {
    severity_label {
      comparison = "EQUALS"
      value      = "CRITICAL"
    }
  }

  depends_on = [aws_securityhub_account.this]
}

########################################
# XDR Category Insights (GuardDuty-driven)
# IMPORTANT:
# - Avoid multiple "type" blocks in one insight (often behaves like AND).
# - If you need OR logic, split into separate insights.
########################################

#
# XDR-01A: Ransomware patterns (HIGH/CRITICAL)
#
resource "aws_securityhub_insight" "xdr_ransomware_high" {
  count = var.enable_securityhub ? 1 : 0

  name               = "${var.securityhub_insight_prefix}-xdr-ransomware-high"
  group_by_attribute = "ResourceId"

  filters {
    product_name {
      comparison = "EQUALS"
      value      = "GuardDuty"
    }

    type {
      comparison = "PREFIX"
      value      = "Backdoor:EC2/Ransomware"
    }

    severity_label {
      comparison = "EQUALS"
      value      = "HIGH"
    }
  }

  depends_on = [aws_securityhub_account.this]
}

resource "aws_securityhub_insight" "xdr_ransomware_critical" {
  count = var.enable_securityhub ? 1 : 0

  name               = "${var.securityhub_insight_prefix}-xdr-ransomware-critical"
  group_by_attribute = "ResourceId"

  filters {
    product_name {
      comparison = "EQUALS"
      value      = "GuardDuty"
    }

    type {
      comparison = "PREFIX"
      value      = "Backdoor:EC2/Ransomware"
    }

    severity_label {
      comparison = "EQUALS"
      value      = "CRITICAL"
    }
  }

  depends_on = [aws_securityhub_account.this]
}

#
# XDR-02A: Crypto-mining activity (MEDIUM/HIGH/CRITICAL)
#
resource "aws_securityhub_insight" "xdr_crypto_mining_medium" {
  count = var.enable_securityhub ? 1 : 0

  name               = "${var.securityhub_insight_prefix}-xdr-crypto-mining-medium"
  group_by_attribute = "ResourceId"

  filters {
    product_name {
      comparison = "EQUALS"
      value      = "GuardDuty"
    }

    type {
      comparison = "PREFIX"
      value      = "CryptoCurrency:EC2"
    }

    severity_label {
      comparison = "EQUALS"
      value      = "MEDIUM"
    }
  }

  depends_on = [aws_securityhub_account.this]
}

resource "aws_securityhub_insight" "xdr_crypto_mining_high" {
  count = var.enable_securityhub ? 1 : 0

  name               = "${var.securityhub_insight_prefix}-xdr-crypto-mining-high"
  group_by_attribute = "ResourceId"

  filters {
    product_name {
      comparison = "EQUALS"
      value      = "GuardDuty"
    }

    type {
      comparison = "PREFIX"
      value      = "CryptoCurrency:EC2"
    }

    severity_label {
      comparison = "EQUALS"
      value      = "HIGH"
    }
  }

  depends_on = [aws_securityhub_account.this]
}

resource "aws_securityhub_insight" "xdr_crypto_mining_critical" {
  count = var.enable_securityhub ? 1 : 0

  name               = "${var.securityhub_insight_prefix}-xdr-crypto-mining-critical"
  group_by_attribute = "ResourceId"

  filters {
    product_name {
      comparison = "EQUALS"
      value      = "GuardDuty"
    }

    type {
      comparison = "PREFIX"
      value      = "CryptoCurrency:EC2"
    }

    severity_label {
      comparison = "EQUALS"
      value      = "CRITICAL"
    }
  }

  depends_on = [aws_securityhub_account.this]
}

#
# XDR-03: Credential compromise / IAM suspicious activity (HIGH/CRITICAL split)
#
resource "aws_securityhub_insight" "xdr_iam_compromise_high" {
  count = var.enable_securityhub ? 1 : 0

  name               = "${var.securityhub_insight_prefix}-xdr-iam-compromise-high"
  group_by_attribute = "ResourceId"

  filters {
    product_name {
      comparison = "EQUALS"
      value      = "GuardDuty"
    }

    type {
      comparison = "PREFIX"
      value      = "UnauthorizedAccess:IAMUser"
    }

    severity_label {
      comparison = "EQUALS"
      value      = "HIGH"
    }
  }

  depends_on = [aws_securityhub_account.this]
}

resource "aws_securityhub_insight" "xdr_iam_compromise_critical" {
  count = var.enable_securityhub ? 1 : 0

  name               = "${var.securityhub_insight_prefix}-xdr-iam-compromise-critical"
  group_by_attribute = "ResourceId"

  filters {
    product_name {
      comparison = "EQUALS"
      value      = "GuardDuty"
    }

    type {
      comparison = "PREFIX"
      value      = "UnauthorizedAccess:IAMUser"
    }

    severity_label {
      comparison = "EQUALS"
      value      = "CRITICAL"
    }
  }

  depends_on = [aws_securityhub_account.this]
}

#
# XDR-04: Recon / probing behavior (MEDIUM+)
#
resource "aws_securityhub_insight" "xdr_recon_medium" {
  count = var.enable_securityhub ? 1 : 0

  name               = "${var.securityhub_insight_prefix}-xdr-recon-medium"
  group_by_attribute = "AwsAccountId"

  filters {
    product_name {
      comparison = "EQUALS"
      value      = "GuardDuty"
    }

    type {
      comparison = "PREFIX"
      value      = "Recon:"
    }

    severity_label {
      comparison = "EQUALS"
      value      = "MEDIUM"
    }
  }

  depends_on = [aws_securityhub_account.this]
}

resource "aws_securityhub_insight" "xdr_recon_high" {
  count = var.enable_securityhub ? 1 : 0

  name               = "${var.securityhub_insight_prefix}-xdr-recon-high"
  group_by_attribute = "AwsAccountId"

  filters {
    product_name {
      comparison = "EQUALS"
      value      = "GuardDuty"
    }

    type {
      comparison = "PREFIX"
      value      = "Recon:"
    }

    severity_label {
      comparison = "EQUALS"
      value      = "HIGH"
    }
  }

  depends_on = [aws_securityhub_account.this]
}

#
# XDR-05: Payments API abuse signals (tag-scoped, best-effort)
#
resource "aws_securityhub_insight" "xdr_payments_api_abuse" {
  count = var.enable_securityhub ? 1 : 0

  name               = "${var.securityhub_insight_prefix}-xdr-payments-api-abuse"
  group_by_attribute = "ResourceId"

  filters {
    product_name {
      comparison = "EQUALS"
      value      = "GuardDuty"
    }

    type {
      comparison = "PREFIX"
      value      = "UnauthorizedAccess:EC2/MaliciousIPCaller"
    }

    resource_tags {
      key        = "app"
      comparison = "EQUALS"
      value      = "payments-api"
    }

    severity_label {
      comparison = "EQUALS"
      value      = "MEDIUM"
    }
  }

  depends_on = [aws_securityhub_account.this]
}

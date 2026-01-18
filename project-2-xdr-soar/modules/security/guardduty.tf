resource "aws_guardduty_detector" "this" {
  enable = var.enable_guardduty

  # Older provider versions support these; generally safe
  datasources {
    s3_logs {
      enable = true
    }

    kubernetes {
      audit_logs {
        enable = true
      }
    }

    # Malware protection is newer in provider schema.
    # Render only if enabled to avoid schema errors on older versions.
    dynamic "malware_protection" {
      for_each = var.enable_guardduty_malware_protection ? [1] : []
      content {
        scan_ec2_instance_with_findings {
          ebs_volumes {
            enable = true
          }
        }
      }
    }
  }

  finding_publishing_frequency = "FIFTEEN_MINUTES"
}

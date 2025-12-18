# INTENTIONAL INSECURE DEMO (Week 3)
# Purpose: trigger Conftest/OPA policy failures for SOC evidence.
# Do not use in production.

variable "enable_insecure_demo" {
  type    = bool
  default = true
}

resource "aws_s3_bucket" "unencrypted_demo" {
  count  = var.enable_insecure_demo ? 1 : 0
  bucket = "test-no-encryption"
}

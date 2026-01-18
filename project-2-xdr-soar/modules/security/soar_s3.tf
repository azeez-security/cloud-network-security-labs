########################################
# SOAR Evidence S3 Bucket
########################################

resource "aws_s3_bucket" "soar_evidence" {
  count  = (var.enable_soar && var.enable_soar_evidence_s3 && var.soar_evidence_bucket_name != "") ? 1 : 0
  bucket = var.soar_evidence_bucket_name

  tags = {
    Project = var.project_name
    Layer   = "xdr-soar"
    Purpose = "soar-evidence"
  }
}

########################################
# Block ALL public access (recommended)
########################################

resource "aws_s3_bucket_public_access_block" "soar_evidence" {
  count  = length(aws_s3_bucket.soar_evidence) > 0 ? 1 : 0
  bucket = aws_s3_bucket.soar_evidence[0].id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

########################################
# Enforce bucket ownership (prevents ACL issues)
########################################

resource "aws_s3_bucket_ownership_controls" "soar_evidence" {
  count  = length(aws_s3_bucket.soar_evidence) > 0 ? 1 : 0
  bucket = aws_s3_bucket.soar_evidence[0].id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

########################################
# Default encryption at rest (SSE-S3)
# (Use KMS later if you want)
########################################

resource "aws_s3_bucket_server_side_encryption_configuration" "soar_evidence" {
  count  = length(aws_s3_bucket.soar_evidence) > 0 ? 1 : 0
  bucket = aws_s3_bucket.soar_evidence[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

########################################
# Versioning (as you had it)
########################################

resource "aws_s3_bucket_versioning" "soar_evidence" {
  count  = length(aws_s3_bucket.soar_evidence) > 0 ? 1 : 0
  bucket = aws_s3_bucket.soar_evidence[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

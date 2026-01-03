data "aws_caller_identity" "current" {}

# -------------------------------
# KMS CMK (bank-grade)
# -------------------------------
data "aws_iam_policy_document" "kms_key_policy" {
  statement {
    sid = "AllowKeyAdministrationToAccountRoot"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }

    actions = [
      "kms:Create*",
      "kms:Describe*",
      "kms:Enable*",
      "kms:List*",
      "kms:Put*",
      "kms:Update*",
      "kms:Revoke*",
      "kms:Disable*",
      "kms:Get*",
      "kms:Delete*",
      "kms:ScheduleKeyDeletion",
      "kms:CancelKeyDeletion",
      "kms:TagResource",
      "kms:UntagResource",
    ]
    resources = ["*"]
  }

  statement {
    sid = "AllowLogWriterEncryptOnly"

    principals {
      type        = "AWS"
      identifiers = [var.log_writer_role_arn]
    }

    actions = [
      "kms:Encrypt",
      "kms:GenerateDataKey",
      "kms:GenerateDataKeyWithoutPlaintext",
      "kms:DescribeKey",
    ]
    resources = ["*"]
  }

  statement {
    sid = "AllowSOCDecrypt"

    principals {
      type        = "AWS"
      identifiers = [var.soc_reader_role_arn]
    }

    actions   = ["kms:Decrypt", "kms:DescribeKey"]
    resources = ["*"]
  }

  statement {
    sid = "AllowAuditDecrypt"

    principals {
      type        = "AWS"
      identifiers = [var.audit_reader_role_arn]
    }

    actions   = ["kms:Decrypt", "kms:DescribeKey"]
    resources = ["*"]
  }

  statement {
    sid = "AllowBreakGlassDecrypt"

    principals {
      type        = "AWS"
      identifiers = [var.break_glass_role_arn]
    }

    actions   = ["kms:Decrypt", "kms:DescribeKey"]
    resources = ["*"]
  }
}

resource "aws_kms_key" "forensics" {
  description             = "Forensic log CMK (Tier-1 bank) - immutable evidence"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.kms_key_policy.json

  tags = merge(var.tags, {
    Name           = "kms-forensics-cmk"
    Classification = var.classification
    Retention      = var.retention
  })
}

resource "aws_kms_alias" "forensics" {
  name          = var.kms_alias
  target_key_id = aws_kms_key.forensics.key_id
}

# -------------------------------
# S3 Forensics Vault (standard - non-WORM)
# -------------------------------
resource "aws_s3_bucket" "forensics" {
  bucket = var.bucket_name

  tags = merge(var.tags, {
    Name           = var.bucket_name
    Classification = var.classification
    Retention      = var.retention
  })
}

resource "aws_s3_bucket_public_access_block" "forensics" {
  bucket                  = aws_s3_bucket.forensics.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "forensics" {
  bucket = aws_s3_bucket.forensics.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "forensics" {
  bucket = aws_s3_bucket.forensics.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.forensics.arn
    }
    bucket_key_enabled = true
  }
}

# -------------------------------
# S3 Forensics Vault (WORM via Object Lock)
# NOTE: Object Lock must be enabled at bucket creation time -> new bucket.
# -------------------------------
resource "aws_s3_bucket" "forensics_worm" {
  count               = var.enable_worm ? 1 : 0
  bucket              = var.worm_bucket_name
  object_lock_enabled = true

  tags = merge(var.tags, {
    Name           = var.worm_bucket_name
    Classification = var.classification
    Retention      = var.retention
    WORM           = "true"
  })
}

resource "aws_s3_bucket_public_access_block" "forensics_worm" {
  count                   = var.enable_worm ? 1 : 0
  bucket                  = aws_s3_bucket.forensics_worm[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "forensics_worm" {
  count  = var.enable_worm ? 1 : 0
  bucket = aws_s3_bucket.forensics_worm[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "forensics_worm" {
  count  = var.enable_worm ? 1 : 0
  bucket = aws_s3_bucket.forensics_worm[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.forensics.arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_object_lock_configuration" "forensics_worm" {
  count  = var.enable_worm ? 1 : 0
  bucket = aws_s3_bucket.forensics_worm[0].id

  rule {
    default_retention {
      mode = var.worm_retention_mode
      days = var.worm_retention_days
    }
  }
}

# -------------------------------
# Bucket policy (applies to standard bucket)
# If I enable WORM, I need to attach a separate policy to the WORM bucket too.
# -------------------------------
data "aws_iam_policy_document" "bucket_policy" {
  # Deny non-TLS
  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.forensics.arn,
      "${aws_s3_bucket.forensics.arn}/*",
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  # Deny PutObject without SSE-KMS
  statement {
    sid    = "DenyUnencryptedObjectUploads"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.forensics.arn}/*"]

    condition {
      test     = "StringNotEquals"
      variable = "s3:x-amz-server-side-encryption"
      values   = ["aws:kms"]
    }
  }

  # Deny PutObject not using our CMK
  statement {
    sid    = "DenyWrongKMSKey"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.forensics.arn}/*"]

    condition {
      test     = "StringNotEquals"
      variable = "s3:x-amz-server-side-encryption-aws-kms-key-id"
      values   = [aws_kms_key.forensics.arn]
    }
  }

  # Deny delete (Object Lock later; this prevents accidental deletes now)
  statement {
    sid    = "DenyDeletes"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = [
      "s3:DeleteObject",
      "s3:DeleteObjectVersion",
    ]
    resources = ["${aws_s3_bucket.forensics.arn}/*"]
  }

  # Allow writer to write only
  statement {
    sid    = "AllowLogWriterPutOnly"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [var.log_writer_role_arn]
    }

    actions = [
      "s3:PutObject",
      "s3:AbortMultipartUpload",
    ]
    resources = ["${aws_s3_bucket.forensics.arn}/*"]
  }

  # Allow SOC read (ListBucket must be on bucket ARN; GetObject on object ARN)
  statement {
    sid    = "AllowSOCList"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [var.soc_reader_role_arn]
    }

    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.forensics.arn]
  }

  statement {
    sid    = "AllowSOCGet"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [var.soc_reader_role_arn]
    }

    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.forensics.arn}/*"]
  }

  # Allow Audit read
  statement {
    sid    = "AllowAuditList"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [var.audit_reader_role_arn]
    }

    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.forensics.arn]
  }

  statement {
    sid    = "AllowAuditGet"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [var.audit_reader_role_arn]
    }

    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.forensics.arn}/*"]
  }
}

resource "aws_s3_bucket_policy" "forensics" {
  bucket = aws_s3_bucket.forensics.id
  policy = data.aws_iam_policy_document.bucket_policy.json
}

# --- WORM bucket policy: reuse same guardrails but point at worm bucket ARNs ---
data "aws_iam_policy_document" "worm_bucket_policy" {
  count = var.enable_worm ? 1 : 0

  source_policy_documents = [
    replace(
      replace(
        data.aws_iam_policy_document.bucket_policy.json,
        aws_s3_bucket.forensics.arn,
        aws_s3_bucket.forensics_worm[0].arn
      ),
      "${aws_s3_bucket.forensics.arn}/*",
      "${aws_s3_bucket.forensics_worm[0].arn}/*"
    )
  ]
}

resource "aws_s3_bucket_policy" "forensics_worm" {
  count  = var.enable_worm ? 1 : 0
  bucket = aws_s3_bucket.forensics_worm[0].id
  policy = data.aws_iam_policy_document.worm_bucket_policy[0].json
}

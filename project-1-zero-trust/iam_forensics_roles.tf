resource "aws_iam_role" "forensics_log_writer" {
  name = "${local.name_prefix}-forensics-log-writer"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" },
      Action    = "sts:AssumeRole"
    }]
  })
  tags = local.common_tags
}

resource "aws_iam_role" "forensics_soc_reader" {
  name               = "${local.name_prefix}-forensics-soc-reader"
  assume_role_policy = aws_iam_role.forensics_log_writer.assume_role_policy
  tags               = local.common_tags
}

resource "aws_iam_role" "forensics_audit_reader" {
  name               = "${local.name_prefix}-forensics-audit-reader"
  assume_role_policy = aws_iam_role.forensics_log_writer.assume_role_policy
  tags               = local.common_tags
}

resource "aws_iam_role" "forensics_break_glass" {
  name               = "${local.name_prefix}-forensics-break-glass"
  assume_role_policy = aws_iam_role.forensics_log_writer.assume_role_policy
  tags               = local.common_tags
}

# modules/forensics/worm.tf
# Immutable S3 policy for forensic WORM bucket

resource "aws_s3_bucket_policy" "forensics_worm_immutable" {
  # Create the policy only when the WORM bucket is enabled
  count  = var.enable_worm ? 1 : 0
  bucket = aws_s3_bucket.forensics_worm[count.index].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyDeleteOrOverwriteExceptBreakGlass"
        Effect    = "Deny"
        Principal = "*"

        Action = [
          "s3:DeleteObject",
          "s3:DeleteObjectVersion",
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:PutObjectVersionAcl"
        ]

        Resource = [
          "${aws_s3_bucket.forensics_worm[count.index].arn}/*"
        ]

        Condition = {
          StringNotEquals = {
            "aws:PrincipalArn" = var.break_glass_role_arn
          }
        }
      }
    ]
  })
}

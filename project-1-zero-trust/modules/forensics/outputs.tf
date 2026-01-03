output "forensics_bucket_arn" { value = aws_s3_bucket.forensics.arn }
output "forensics_kms_key_arn" { value = aws_kms_key.forensics.arn }
output "forensics_kms_alias" { value = aws_kms_alias.forensics.name }

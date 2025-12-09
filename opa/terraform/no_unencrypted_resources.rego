package terraform.encryption

# Bank-grade guardrail:
# Deny any Terraform plan that creates storage or logging resources
# without encryption enabled (KMS or equivalent).

default deny = []

###############################################################################
# Helpers
###############################################################################

# Convenience: iterate over every planned resource change
resource_change[rc] {
  rc := input.resource_changes[_]
  rc.mode == "managed"
  rc.change.actions[_] == "create"  # focus on creates; extend later for update
}

###############################################################################
# S3 – must have server-side encryption
###############################################################################

unencrypted_s3[msg] {
  rc := resource_change[_]
  rc.type == "aws_s3_bucket"

  after := rc.change.after
  # No SSE block defined
  not after.server_side_encryption_configuration

  bucket_name := after.bucket
  msg := sprintf("S3 bucket %q has no server_side_encryption_configuration (KMS encryption required).", [bucket_name])
}

###############################################################################
# EBS – must be encrypted
###############################################################################

unencrypted_ebs[msg] {
  rc := resource_change[_]
  rc.type == "aws_ebs_volume"

  after := rc.change.after
  not after.encrypted
  volume_id := rc.name

  msg := sprintf("EBS volume %q has encrypted = false (KMS-backed encryption required).", [volume_id])
}

# Root volumes created via aws_instance
unencrypted_ebs_root[msg] {
  rc := resource_change[_]
  rc.type == "aws_instance"

  after := rc.change.after
  block := after.root_block_device

  not block.encrypted

  msg := sprintf("EC2 instance %q root_block_device is not encrypted (encrypted = false or omitted).", [after.tags.Name])
}

###############################################################################
# RDS – must be storage_encrypted with KMS key
###############################################################################

unencrypted_rds[msg] {
  rc := resource_change[_]
  rc.type == "aws_db_instance"

  after := rc.change.after

  not after.storage_encrypted
  identifier := after.identifier

  msg := sprintf("RDS instance %q has storage_encrypted = false (required for banking workloads).", [identifier])
}

missing_rds_kms_key[msg] {
  rc := resource_change[_]
  rc.type == "aws_db_instance"

  after := rc.change.after

  after.storage_encrypted
  not after.kms_key_id

  identifier := after.identifier
  msg := sprintf("RDS instance %q is encrypted but has no kms_key_id set (must be CMK, not default).", [identifier])
}

###############################################################################
# Lambda – environment variables must be encrypted with KMS CMK
###############################################################################

unencrypted_lambda_env[msg] {
  rc := resource_change[_]
  rc.type == "aws_lambda_function"

  after := rc.change.after

  # Lambda allows kms_key_arn to encrypt env variables.
  not after.kms_key_arn

  fn_name := after.function_name
  msg := sprintf("Lambda function %q has environment variables without kms_key_arn (KMS CMK required).", [fn_name])
}

###############################################################################
# Master deny rule – used by Conftest / OPA
###############################################################################

deny[msg] {
  msg := unencrypted_s3[_]
}

deny[msg] {
  msg := unencrypted_ebs[_]
}

deny[msg] {
  msg := unencrypted_ebs_root[_]
}

deny[msg] {
  msg := unencrypted_rds[_]
}

deny[msg] {
  msg := missing_rds_kms_key[_]
}

deny[msg] {
  msg := unencrypted_lambda_env[_]
}

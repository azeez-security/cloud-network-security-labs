package terraform.encryption

import rego.v1

###############################################################################
# Helpers
###############################################################################

# Managed resources being CREATED in this plan
resource_change contains rc if {
  rc := input.resource_changes[_]
  rc.mode == "managed"
  rc.change.actions[_] == "create"
}

# S3: encryption config exists AND uses aws:kms
has_s3_kms_encryption(bucket_name) if {
  enc := input.resource_changes[_]
  enc.mode == "managed"
  enc.type == "aws_s3_bucket_server_side_encryption_configuration"
  enc.change.after.bucket == bucket_name

  rule := enc.change.after.rule
  def := rule.apply_server_side_encryption_by_default
  def.sse_algorithm == "aws:kms"
}

# S3: Public Access Block exists AND all flags are true
has_s3_public_access_block(bucket_name) if {
  pab := input.resource_changes[_]
  pab.mode == "managed"
  pab.type == "aws_s3_bucket_public_access_block"
  pab.change.after.bucket == bucket_name

  pab.change.after.block_public_acls
  pab.change.after.ignore_public_acls
  pab.change.after.block_public_policy
  pab.change.after.restrict_public_buckets
}

###############################################################################
# Deny rules (Conftest reads `deny`)
###############################################################################

# S3 bucket must have KMS server-side encryption (via aws_s3_bucket_server_side_encryption_configuration)
deny contains result if {
  rc := resource_change[_]
  rc.type == "aws_s3_bucket"

  after := rc.change.after
  bucket_name := after.bucket

  not has_s3_kms_encryption(bucket_name)

  result := {
    "msg": sprintf("S3 bucket %q has no server-side encryption (KMS required).", [bucket_name]),
    "severity": "CRITICAL",
    "resource": bucket_name,
  }
}

# S3 bucket must have Public Access Block (via aws_s3_bucket_public_access_block)
deny contains result if {
  rc := resource_change[_]
  rc.type == "aws_s3_bucket"

  after := rc.change.after
  bucket_name := after.bucket

  not has_s3_public_access_block(bucket_name)

  result := {
    "msg": sprintf("S3 bucket %q missing Public Access Block configuration.", [bucket_name]),
    "severity": "HIGH",
    "resource": bucket_name,
  }
}

# EBS volume must be encrypted
deny contains result if {
  rc := resource_change[_]
  rc.type == "aws_ebs_volume"

  after := rc.change.after
  not after.encrypted

  result := {
    "msg": sprintf("EBS volume %q has encrypted=false (KMS-backed encryption required).", [rc.name]),
    "severity": "HIGH",
    "resource": rc.name,
  }
}

# EC2 root block device must be encrypted (treat missing as non-compliant)
deny contains result if {
  rc := resource_change[_]
  rc.type == "aws_instance"

  after := rc.change.after

  some i
  block := after.root_block_device[i]
  not block.encrypted

  inst := after.tags.Name
  result := {
    "msg": sprintf("EC2 instance %q root_block_device is not encrypted.", [inst]),
    "severity": "HIGH",
    "resource": inst,
  }
}

# RDS must be storage_encrypted
deny contains result if {
  rc := resource_change[_]
  rc.type == "aws_db_instance"

  after := rc.change.after
  not after.storage_encrypted

  id := after.identifier
  result := {
    "msg": sprintf("RDS instance %q has storage_encrypted=false.", [id]),
    "severity": "CRITICAL",
    "resource": id,
  }
}

# RDS must specify a KMS key when encrypted
deny contains result if {
  rc := resource_change[_]
  rc.type == "aws_db_instance"

  after := rc.change.after
  after.storage_encrypted
  not after.kms_key_id

  id := after.identifier
  result := {
    "msg": sprintf("RDS instance %q is encrypted but has no kms_key_id set (CMK required).", [id]),
    "severity": "HIGH",
    "resource": id,
  }
}

# Lambda env vars => must set kms_key_arn
deny contains result if {
  rc := resource_change[_]
  rc.type == "aws_lambda_function"

  after := rc.change.after
  after.environment.variables
  count(after.environment.variables) > 0

  not after.kms_key_arn

  fn := after.function_name
  result := {
    "msg": sprintf("Lambda function %q has environment variables but no kms_key_arn (CMK required).", [fn]),
    "severity": "HIGH",
    "resource": fn,
  }
}

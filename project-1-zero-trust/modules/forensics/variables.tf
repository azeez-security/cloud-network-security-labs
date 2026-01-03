variable "bucket_name" {
  type = string
}

variable "kms_alias" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "classification" {
  type = string
}

variable "retention" {
  type = string
}

# Role ARNs to enforce separation of duties
variable "log_writer_role_arn" {
  type = string
}

variable "soc_reader_role_arn" {
  type = string
}

variable "audit_reader_role_arn" {
  type = string
}

variable "break_glass_role_arn" {
  type        = string
  description = "IAM role ARN allowed to bypass WORM in emergency"
}

# -------------------------------
# OPTIONAL: WORM / Object Lock bucket settings
# Object Lock must be enabled at bucket creation time -> use a NEW bucket name
# -------------------------------
variable "enable_worm" {
  type    = bool
  default = false
}

variable "worm_bucket_name" {
  type    = string
  default = null
}

# Recommended for labs: GOVERNANCE
# Use COMPLIANCE only when you fully understand the irreversible retention implications
variable "worm_retention_mode" {
  type    = string
  default = "GOVERNANCE"

  validation {
    condition     = contains(["GOVERNANCE", "COMPLIANCE"], var.worm_retention_mode)
    error_message = "worm_retention_mode must be GOVERNANCE or COMPLIANCE."
  }
}

variable "worm_retention_days" {
  type    = number
  default = 90

  validation {
    condition     = var.worm_retention_days >= 1
    error_message = "worm_retention_days must be at least 1."
  }
}

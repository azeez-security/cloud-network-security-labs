variable "enable_soar" {
  description = "Enable SOAR automation (EventBridge -> Lambda runbooks)."
  type        = bool
  default     = false
}

variable "enable_soar_evidence_s3" {
  description = "Store evidence artifacts in S3 (recommended)."
  type        = bool
  default     = false
}

variable "soar_evidence_bucket_name" {
  description = "S3 bucket name for SOAR evidence."
  type        = string
  default     = ""
}

variable "enable_soar_iam_disable" {
  type    = bool
  default = true
}

variable "enable_soar_ec2_quarantine" {
  type    = bool
  default = true
}

variable "enable_soar_snapshot" {
  type    = bool
  default = true
}

variable "soar_quarantine_sg_id" {
  description = "Optional quarantine SG for enforced EC2 isolation. Leave empty for tag-only mode."
  type        = string
  default     = ""
}

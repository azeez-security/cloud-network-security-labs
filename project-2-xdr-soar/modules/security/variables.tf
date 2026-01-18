variable "project_name" {
  description = "Project identifier used for tagging / naming"
  type        = string
}

variable "enable_guardduty" {
  description = "Enable AWS GuardDuty"
  type        = bool
  default     = true
}

variable "enable_securityhub" {
  description = "Enable AWS Security Hub"
  type        = bool
  default     = true
}

variable "securityhub_standards" {
  description = "Security Hub standards to enable (per region)"
  type        = list(string)
  default = [
    "aws-foundational-security-best-practices/v/1.0.0",
    "cis-aws-foundations-benchmark/v/1.2.0",
    "pci-dss/v/3.2.1",
  ]
}

variable "securityhub_insight_prefix" {
  description = "Prefix for custom Security Hub insights (banking XDR)"
  type        = string
  default     = "banking-xdr"
}

variable "enable_guardduty_malware_protection" {
  description = "Enable GuardDuty Malware Protection (may require newer AWS provider)."
  type        = bool
  default     = false
}

variable "enable_detective" {
  type    = bool
  default = true
}

variable "enable_detective_members" {
  type    = bool
  default = false   # SAFE default: single account lab
}

variable "detective_member_account_id" {
  type    = string
  default = ""
}

variable "detective_member_email" {
  type    = string
  default = ""
}

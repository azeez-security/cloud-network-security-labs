variable "project_name" {
  type        = string
  description = "Short name for this project"
  default     = "cloud-bank-xdr-soar"
}

variable "enable_guardduty" {
  type    = bool
  default = true
}

variable "enable_securityhub" {
  type    = bool
  default = true
}

variable "enable_detective" {
  type    = bool
  default = true
}

variable "securityhub_insight_prefix" {
  description = "Prefix for Security Hub XDR insights"
  type        = string
}

variable "securityhub_standards" {
  description = "Security Hub standards to enable"
  type        = list(string)
}

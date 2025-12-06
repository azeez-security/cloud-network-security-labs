variable "vpc_cidr" {
  type        = string
  description = "CIDR for the VPC"
}

variable "azs" {
  type        = list(string)
  description = "Availability zones"
}

variable "project_name" {
  type        = string
}

variable "environment" {
  type        = string
}

variable "tags" {
  type        = map(string)
  default     = {}
}

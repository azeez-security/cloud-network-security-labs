variable "vpc_id" {
  type        = string
  description = "ID of the VPC"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block of the VPC"
}

variable "app_subnet_ids" {
  type        = list(string)
  description = "Private app subnet IDs"
}

variable "db_subnet_ids" {
  type        = list(string)
  description = "Private DB subnet IDs"
}

variable "logging_subnet_ids" {
  type        = list(string)
  description = "Logging / security tools subnet IDs"
}

variable "tags" {
  type    = map(string)
  default = {}
}

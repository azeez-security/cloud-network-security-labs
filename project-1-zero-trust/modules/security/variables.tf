variable "vpc_id" {
  type = string
}

variable "app_subnet_ids" {
  type = list(string)
}

variable "db_subnet_ids" {
  type = list(string)
}

variable "logging_subnet_ids" {
  type = list(string)
}

variable "tags" {
  type    = map(string)
  default = {}
}

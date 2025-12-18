variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "app_subnet_ids" {
  description = "App tier subnet IDs"
  type        = list(string)
}

variable "db_subnet_ids" {
  description = "DB tier subnet IDs"
  type        = list(string)
}

variable "logging_subnet_ids" {
  description = "Logging / security tools subnet IDs"
  type        = list(string)
}

variable "tags" {
  description = "Common tags for all security resources"
  type        = map(string)
  default     = {}
}

variable "db_backup_cidrs" {
  description = "CIDR ranges that the core DB is allowed to talk to (backups/patching/ops). Keep very tight."
  type        = list(string)
  default     = ["10.0.240.0/24"]
}

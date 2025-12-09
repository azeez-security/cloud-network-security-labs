output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "ID of the Zero Trust VPC"
}

output "public_subnet_ids" {
  value       = module.subnets.public_subnet_ids
  description = "Public subnet IDs (for load balancers / bastion)"
}

output "private_app_subnet_ids" {
  value       = module.subnets.private_app_subnet_ids
  description = "Private app subnet IDs"
}

output "private_db_subnet_ids" {
  value       = module.subnets.private_db_subnet_ids
  description = "Private DB subnet IDs"
}

output "logging_subnet_ids" {
  value       = module.subnets.logging_subnet_ids
  description = "Logging / security tools subnet IDs"
}

output "vpc_cidr" {
  value       = var.vpc_cidr
  description = "CIDR of the Tier-1 banking VPC"
}

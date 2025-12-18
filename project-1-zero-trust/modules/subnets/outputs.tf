output "public_subnet_ids" {
  value = [for s in aws_subnet.public : s.id]
}

output "private_app_subnet_ids" {
  value = [for s in aws_subnet.private_app : s.id]
}

output "private_db_subnet_ids" {
  value = [for s in aws_subnet.private_db : s.id]
}

output "logging_subnet_ids" {
  value = [for s in aws_subnet.logging : s.id]
}

output "public_route_table_id" {
  value       = aws_route_table.public.id
  description = "Route table ID for public / ATM edge subnets"
}

output "private_app_route_table_id" {
  value       = aws_route_table.private_app.id
  description = "Route table ID for core-banking app subnets"
}

output "private_db_route_table_id" {
  value       = aws_route_table.private_db.id
  description = "Route table ID for core DB / fraud-AML subnets"
}

output "logging_route_table_id" {
  value       = aws_route_table.logging.id
  description = "Route table ID for logging / security tooling subnets"
}

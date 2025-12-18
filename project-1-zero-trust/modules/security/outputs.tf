output "alb_edge_sg_id" {
  value       = aws_security_group.alb_edge.id
  description = "SG for Internet-facing ALB / ATM edge"
}

output "core_app_sg_id" {
  value       = aws_security_group.core_app.id
  description = "SG for core-banking app services"
}

output "core_db_sg_id" {
  value       = aws_security_group.core_db.id
  description = "SG for core banking DB"
}

output "fraud_analytics_sg_id" {
  value       = aws_security_group.fraud_analytics.id
  description = "SG for fraud / AML analytics tier"
}

output "logging_tools_sg_id" {
  value       = aws_security_group.logging_tools.id
  description = "SG for logging / security tooling"
}

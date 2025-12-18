output "db_nacl_id" {
  value       = aws_network_acl.db.id
  description = "NACL ID for the DB tier"
}

output "logging_nacl_id" {
  value       = aws_network_acl.logging.id
  description = "NACL ID for the logging tier"
}

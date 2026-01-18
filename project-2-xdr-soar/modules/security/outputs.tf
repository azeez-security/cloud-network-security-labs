########################################
# Module Outputs – Security Platform
########################################

output "guardduty_detector_id" {
  description = "GuardDuty detector ID"
  value       = aws_guardduty_detector.this.id
}

output "securityhub_account_id" {
  description = "Security Hub account ID (null if disabled)"
  value       = try(aws_securityhub_account.this[0].id, null)
}

output "detective_graph_id" {
  description = "Detective graph ID (null if disabled)"
  value       = try(aws_detective_graph.this[0].id, null)
}

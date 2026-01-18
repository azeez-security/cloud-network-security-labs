output "guardduty_detector_id" {
  value       = module.security_platform.guardduty_detector_id
  description = "GuardDuty detector ID"
}

output "securityhub_account_id" {
  value       = module.security_platform.securityhub_account_id
  description = "Security Hub account ID"
}

output "detective_graph_id" {
  value       = module.security_platform.detective_graph_id
  description = "Detective graph ID"
}

output "common_tags" {
  description = "Common tags applied to all resources"
  value       = local.common_tags
}

output "account_id" {
  description = "AWS account ID"
  value       = data.aws_caller_identity.current.account_id
}

output "region" {
  description = "AWS region"
  value       = data.aws_region.current.name
}

output "naming_prefix" {
  description = "Naming prefix for resources"
  value       = "${var.project_name}-${var.environment}-${var.service}"
}
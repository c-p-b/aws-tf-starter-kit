terraform {
  required_version = ">= 1.5.0"
}

locals {
  # Validation checks
  valid_environment = contains(var.allowed_environments, var.environment)
  valid_service     = contains(var.allowed_services, var.service)
  valid_backend_key = can(regex("^${var.environment}/${var.service}/terraform\\.tfstate$", var.backend_key))
  has_aws_provider  = contains(keys(var.required_providers), "aws")
  
  validation_errors = compact([
    !local.valid_environment ? "Invalid environment: ${var.environment}. Must be one of: ${join(", ", var.allowed_environments)}" : "",
    !local.valid_service ? "Invalid service: ${var.service}. Must be one of: ${join(", ", var.allowed_services)}" : "",
    !local.valid_backend_key ? "Invalid backend key format. Must follow pattern: {environment}/{service}/terraform.tfstate" : "",
    !local.has_aws_provider ? "Missing AWS provider in required_providers block" : "",
    !var.uses_base_module ? "All deployments must use the deployment-base module" : ""
  ])
}

output "validation_passed" {
  description = "Whether all validations passed"
  value       = length(local.validation_errors) == 0
}

output "validation_errors" {
  description = "List of validation errors"
  value       = local.validation_errors
}
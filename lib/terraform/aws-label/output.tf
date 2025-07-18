output "id" {
  value       = local.id
  description = "The ID of the resource or application. Useful for setting `name` properties"
}

output "prefix" {
  value       = format("%s-", local.id)
  description = "The ID of the resource suffixed with a hyphen. Useful for setting `name_prefix` properties"
}

output "ou" {
  value       = var.ou
  description = "The OU identifier"
}

output "name" {
  value       = var.name
  description = "The canonical name of the resource or application"
}

output "team" {
  value       = var.team
  description = "The identifier of the team that owns the resource or application"
}

output "environment" {
  value       = var.environment
  description = "The environment of the resource or application"
}

output "tags" {
  value       = local.tags
  description = "The normalized tags for the resource or application"
}

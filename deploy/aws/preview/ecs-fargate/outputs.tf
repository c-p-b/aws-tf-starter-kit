output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = module.ecr_repository.repository_url
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.ecs_cluster.cluster_name
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = module.ecs_service.service_name
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "log_group_name" {
  description = "CloudWatch log group name for the ECS service"
  value       = module.ecs_service.log_group_name
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.alb.dns_name
}

output "alb_hosted_zone_id" {
  description = "Hosted zone ID of the Application Load Balancer"
  value       = module.alb.zone_id
}

output "api_url" {
  description = "Public API URL"
  value       = "http://${module.alb.dns_name}"
}

output "api_key" {
  description = "API key for authentication"
  value       = random_password.api_key.result
  sensitive   = true
}
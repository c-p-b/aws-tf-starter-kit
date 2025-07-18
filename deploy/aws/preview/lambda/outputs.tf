output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = module.lambda_function.function_arn
}

output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = module.lambda_function.function_name
}

output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = module.ecr_repository.repository_url
}

output "ecr_repository_arn" {
  description = "ARN of the ECR repository"
  value       = module.ecr_repository.repository_arn
}

output "lambda_function_url" {
  description = "Public URL to invoke the Lambda function"
  value       = module.lambda_function.function_url
}

output "api_key" {
  description = "API key for accessing the Lambda function"
  value       = module.lambda_function.api_key
  sensitive   = true
}

output "log_group_name" {
  description = "CloudWatch log group name for the Lambda function"
  value       = module.lambda_function.log_group_name
}
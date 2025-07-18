terraform {
  required_version = ">= 1.5.0"
}

provider "aws" {
  region = "us-east-1"
}

module "lambda_function" {
  source = "../../lib/terraform/lambda-container"

  function_name = var.function_name
  
  # Use a simple public image for testing
  container_image_uri = "public.ecr.aws/lambda/python:3.11"
  
  environment_variables = {
    ENVIRONMENT = var.environment
    TEST        = "true"
  }

  tags = {
    Environment = var.environment
    Test        = "true"
  }
}

variable "function_name" {
  description = "Name of the Lambda function"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

output "function_name" {
  value = module.lambda_function.function_name
}

output "function_arn" {
  value = module.lambda_function.function_arn
}

output "role_arn" {
  value = module.lambda_function.role_arn
}
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Test the Lambda container module with a public container image
module "lambda_container" {
  source = "../../lib/terraform/lambda-container"
  
  function_name = var.function_name
  
  # Use AWS's public Lambda base image for testing
  # This avoids needing to build/push a custom image during tests
  container_image_uri = "public.ecr.aws/lambda/python:3.11"
  
  # Minimal memory/timeout for testing
  memory_size = 128
  timeout     = 10
  
  environment_variables = {
    TEST_ENV = "true"
    FUNCTION = var.function_name
  }
  
  tags = {
    Environment = "test"
    TestRun     = "true"
  }
}

variable "function_name" {
  description = "Name of the Lambda function"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

output "function_name" {
  value = module.lambda_container.function_name
}

output "function_arn" {
  value = module.lambda_container.function_arn
}

output "role_arn" {
  value = module.lambda_container.role_arn
}
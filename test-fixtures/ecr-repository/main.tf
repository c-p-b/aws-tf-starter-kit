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

# Test the ECR repository module
module "ecr_repository" {
  source = "../../lib/terraform/ecr-repository"
  
  repository_name = var.repository_name
  
  # Simple lifecycle policy for testing
  lifecycle_policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 3 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 3
      }
      action = {
        type = "expire"
      }
    }]
  })
  
  tags = {
    Environment = "test"
    TestRun     = "true"
  }
}

variable "repository_name" {
  description = "Name of the ECR repository"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

output "repository_url" {
  value = module.ecr_repository.repository_url
}

output "repository_arn" {
  value = module.ecr_repository.repository_arn
}

output "repository_name" {
  value = module.ecr_repository.repository_name
}
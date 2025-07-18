terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
  
  backend "s3" {
    key = "aws/preview/lambda/terraform.tfstate"
  }
}

module "base" {
  source = "../../../../lib/terraform/deployment-base"
  
  environment  = local.environment
  service      = local.service
  project_name = var.project_name
}

module "ecr_repository" {
  source = "../../../../lib/terraform/ecr-repository"
  
  repository_name = "${module.base.naming_prefix}-lambda"
  
  lifecycle_policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 5 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 5
      }
      action = {
        type = "expire"
      }
    }]
  })
  
  tags = module.base.common_tags
}

resource "docker_image" "lambda" {
  name = "${module.ecr_repository.repository_url}:latest"
  
  build {
    context    = "../../../../docker/rest-server"
    dockerfile = "Dockerfile"
    platform   = "linux/amd64"
  }
}

resource "docker_registry_image" "lambda" {
  name = docker_image.lambda.name
  
  depends_on = [module.ecr_repository]
}

module "lambda_function" {
  source = "../../../../lib/terraform/lambda-container"

  function_name = "${module.base.naming_prefix}-rest-api"
  description   = "Containerized REST API Lambda for ${local.environment}"
  
  image_uri = "${module.ecr_repository.repository_url}@${docker_registry_image.lambda.sha256_digest}"
  
  timeout     = 30
  memory_size = 512
  
  environment_variables = {
    ENVIRONMENT  = local.environment
    SERVICE_NAME = local.service
    PROJECT      = var.project_name
  }

  enable_function_url = true
  
  tags = module.base.common_tags
}

locals {
  environment = "preview"
  service     = "lambda"
}
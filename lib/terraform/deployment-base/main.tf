terraform {
  required_version = ">= 1.5.0"
}

locals {
  common_tags = merge(
    var.default_tags,
    {
      Environment = var.environment
      Service     = var.service
      Project     = var.project_name
      ManagedBy   = "terraform"
      Workspace   = terraform.workspace
    },
    var.additional_tags
  )
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
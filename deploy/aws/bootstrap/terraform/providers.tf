provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = "aws-tf-starter-kit"
      ManagedBy = "terraform"
    }
  }
}

variable "aws_region" {
  description = "AWS region for the bootstrap resources"
  type        = string
  default     = "us-east-1"
}
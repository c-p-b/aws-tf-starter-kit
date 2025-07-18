variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "preview"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "aws-tf-starter"
}
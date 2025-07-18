variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "preview"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "aws-tf-starter"
}
variable "environment" {
  description = "Environment name (e.g., preview, staging, production)"
  type        = string
  
  validation {
    condition     = contains(["preview", "staging", "production"], var.environment)
    error_message = "Environment must be one of: preview, staging, production"
  }
}

variable "service" {
  description = "Service name (e.g., lambda, fargate, ecs)"
  type        = string
  
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*$", var.service))
    error_message = "Service name must start with a letter and contain only lowercase letters, numbers, and hyphens"
  }
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "aws-tf-starter"
}

variable "default_tags" {
  description = "Default tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "additional_tags" {
  description = "Additional tags to merge with defaults"
  type        = map(string)
  default     = {}
}
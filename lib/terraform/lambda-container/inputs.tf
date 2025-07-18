variable "function_name" {
  description = "Name of the Lambda function"
  type        = string
}

variable "description" {
  description = "Description of the Lambda function"
  type        = string
  default     = ""
}

variable "image_uri" {
  description = "URI of the container image in ECR"
  type        = string
}

variable "image_command" {
  description = "Override command for the container image"
  type        = list(string)
  default     = null
}

variable "image_entry_point" {
  description = "Override entry point for the container image"
  type        = list(string)
  default     = null
}

variable "image_working_directory" {
  description = "Override working directory for the container image"
  type        = string
  default     = null
}

variable "timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 3
}

variable "memory_size" {
  description = "Lambda function memory size in MB"
  type        = number
  default     = 128
}

variable "environment_variables" {
  description = "Environment variables for the Lambda function"
  type        = map(string)
  default     = {}
}

variable "vpc_config" {
  description = "VPC configuration for the Lambda function"
  type = object({
    subnet_ids         = list(string)
    security_group_ids = list(string)
  })
  default = null
}

variable "policy_arns" {
  description = "List of IAM policy ARNs to attach to the Lambda role"
  type        = list(string)
  default     = []
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "enable_function_url" {
  description = "Whether to create a public Lambda Function URL"
  type        = bool
  default     = false
}

variable "api_key" {
  description = "Simple API key for basic authentication (auto-generated if not provided)"
  type        = string
  default     = null
  sensitive   = true
}
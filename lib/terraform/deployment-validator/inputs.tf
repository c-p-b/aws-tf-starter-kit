variable "environment" {
  description = "Environment being validated"
  type        = string
}

variable "service" {
  description = "Service being validated"
  type        = string
}

variable "backend_key" {
  description = "Backend state key to validate"
  type        = string
}

variable "required_providers" {
  description = "Map of required providers from the deployment"
  type        = map(any)
}

variable "uses_base_module" {
  description = "Whether the deployment uses the base module"
  type        = bool
}

variable "allowed_environments" {
  description = "List of allowed environments"
  type        = list(string)
  default     = ["preview", "staging", "production"]
}

variable "allowed_services" {
  description = "List of allowed services"
  type        = list(string)
  default     = ["lambda", "fargate", "ecs", "api", "web"]
}
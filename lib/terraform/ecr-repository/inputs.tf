variable "repository_name" {
  description = "Name of the ECR repository"
  type        = string
}

variable "image_tag_mutability" {
  description = "The tag mutability setting for the repository"
  type        = string
  default     = "MUTABLE"
  
  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.image_tag_mutability)
    error_message = "Image tag mutability must be either MUTABLE or IMMUTABLE"
  }
}

variable "scan_on_push" {
  description = "Indicates whether images are scanned after being pushed"
  type        = bool
  default     = true
}

variable "lifecycle_policy" {
  description = "The policy document for the lifecycle policy"
  type        = string
  default     = null
}

variable "allowed_principals" {
  description = "List of AWS principals allowed to pull images"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to the repository"
  type        = map(string)
  default     = {}
}
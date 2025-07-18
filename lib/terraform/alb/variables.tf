variable "name" {
  description = "Name of the Application Load Balancer"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the ALB will be created"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the ALB"
  type        = list(string)
}

variable "security_group_rules" {
  description = "Security group rules for the ALB"
  type = object({
    ingress = list(object({
      from_port   = number
      to_port     = number
      protocol    = string
      cidr_blocks = list(string)
      description = string
    }))
  })
}

variable "target_group_config" {
  description = "Target group configuration"
  type = object({
    port        = number
    protocol    = string
    target_type = optional(string, "instance")
    health_check = object({
      path                = string
      healthy_threshold   = number
      unhealthy_threshold = number
      timeout             = number
      interval            = number
      matcher             = string
    })
  })
}

variable "listeners" {
  description = "List of listeners for the ALB"
  type = list(object({
    port     = number
    protocol = string
    default_action = object({
      type = string
    })
  }))
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection for the ALB"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
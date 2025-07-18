variable "service_name" {
  description = "Name of the ECS service"
  type        = string
}

variable "cluster_id" {
  description = "ID of the ECS cluster"
  type        = string
}

variable "launch_type" {
  description = "Launch type for the service (FARGATE or EC2)"
  type        = string
  default     = "FARGATE"
  
  validation {
    condition     = contains(["FARGATE", "EC2"], var.launch_type)
    error_message = "Launch type must be either FARGATE or EC2"
  }
}

variable "network_mode" {
  description = "Network mode for non-Fargate tasks"
  type        = string
  default     = "awsvpc"
}

variable "task_cpu" {
  description = "CPU units for the task"
  type        = string
  default     = "256"
}

variable "task_memory" {
  description = "Memory for the task in MB"
  type        = string
  default     = "512"
}

variable "container_name" {
  description = "Name of the container"
  type        = string
}

variable "container_image" {
  description = "Docker image for the container"
  type        = string
}

variable "container_cpu" {
  description = "CPU units for the container"
  type        = number
  default     = null
}

variable "container_memory" {
  description = "Memory for the container in MB"
  type        = number
  default     = null
}

variable "port_mappings" {
  description = "Port mappings for the container"
  type = list(object({
    containerPort = number
    hostPort      = optional(number)
    protocol      = optional(string)
  }))
  default = []
}

variable "environment_variables" {
  description = "Environment variables for the container"
  type        = map(string)
  default     = {}
}

variable "health_check" {
  description = "Health check configuration for the container"
  type = object({
    command     = list(string)
    interval    = optional(number)
    timeout     = optional(number)
    retries     = optional(number)
    startPeriod = optional(number)
  })
  default = null
}

variable "desired_count" {
  description = "Desired number of tasks"
  type        = number
  default     = 1
}

variable "vpc_id" {
  description = "VPC ID for the service"
  type        = string
  default     = null
}

variable "subnet_ids" {
  description = "Subnet IDs for the service"
  type        = list(string)
  default     = []
}

variable "assign_public_ip" {
  description = "Assign public IP to tasks"
  type        = bool
  default     = false
}

variable "create_security_group" {
  description = "Create a security group for the service"
  type        = bool
  default     = true
}

variable "security_group_rules" {
  description = "Security group rules"
  type = object({
    ingress = list(object({
      from_port   = number
      to_port     = number
      protocol    = string
      cidr_blocks = list(string)
      description = string
    }))
  })
  default = {
    ingress = []
  }
}

variable "additional_security_groups" {
  description = "Additional security groups to attach"
  type        = list(string)
  default     = []
}

variable "load_balancer_config" {
  description = "Load balancer configuration"
  type = object({
    target_group_arn = string
    container_port   = number
  })
  default = null
}

variable "service_discovery_config" {
  description = "Service discovery configuration"
  type = object({
    registry_arn   = string
    port           = optional(number)
    container_name = optional(string)
    container_port = optional(number)
  })
  default = null
}

variable "task_role_policies" {
  description = "List of IAM policy ARNs to attach to the task role"
  type        = list(string)
  default     = null
}

variable "enable_execute_command" {
  description = "Enable ECS Exec for debugging"
  type        = bool
  default     = false
}

variable "deployment_maximum_percent" {
  description = "Maximum percent of tasks to run during deployment"
  type        = number
  default     = 200
}

variable "deployment_minimum_healthy_percent" {
  description = "Minimum healthy percent during deployment"
  type        = number
  default     = 100
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
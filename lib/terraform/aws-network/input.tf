variable "aws_network_cidrs" {
  type = object({
    ipv4 = string
    ipv6 = optional(string)
  })

  validation {
    condition     = can(regex("^10(?:\\.[\\d]{1,3}){3}\\/[\\d]{1,2}", var.aws_network_cidrs.ipv4))
    error_message = "Invalid IPv4 CIDR block. Must be within 10.0.0.0/8 range."
  }
}

variable "aws_network_subnets" {
  description = "A list of maps representing subnets and their configurations, including optional routes"
  type = list(object({
    ipv4_cidr_block            = string
    zone                       = string
    public                     = bool
    route_table_association_id = optional(string)
  }))
}

variable "aws_network_tenancy" {
  type        = string
  default     = "default"
  description = "The tenancy option for instances launched in the VPC"

  validation {
    condition     = contains(["default", "dedicated"], var.aws_network_tenancy)
    error_message = "Must be one of [default, dedicated]."
  }
}

variable "aws_network_enable_dns_hostnames" {
  type        = bool
  default     = true
  description = "Whether or not DNS hostnames are enabled in the VPC"
}
variable "aws_network_enable_dns_support" {
  type        = bool
  default     = true
  description = "Whether or not DNS support is enabled in the VPC"
}

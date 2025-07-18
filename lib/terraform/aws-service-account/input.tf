variable "service_account_enabled" {
  type        = bool
  default     = false
  description = "Whether or not this module is enabled"
}

variable "service_account_inline_policies" {
  type = list(object({
    key  = string
    json = string
  }))

  default     = []
  description = "A list of JSON IAM policy documents for this role"

  validation {
    condition = alltrue([for k in distinct(var.service_account_inline_policies[*].key) :
      can(regex("^[a-z][a-z0-9_-].*[a-z]$", k))
    ])
    error_message = "Keys must begin and end with a letter, and contain only lowercase letters and hyphens."
  }

  validation {
    condition     = length(var.service_account_inline_policies) == length(distinct(var.service_account_inline_policies[*].key))
    error_message = "Policy objects must have unique keys."
  }
}

variable "service_account_managed_policies" {
  type        = list(string)
  default     = []
  description = "A list of AWS-managed IAM Policy ARNS to attach to the role"
}

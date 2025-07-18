variable "iam_role_trust_policy" {
  type        = string
  description = "The JSON document describing the Trust Relationship policy"
}

variable "iam_role_policy_arns" {
  type        = list(string)
  default     = []
  description = "A list of IAM Policy ARNS to attach to the role"
}

variable "iam_role_description" {
  type        = string
  default     = ""
  description = "The description for the role"
}

variable "iam_role_path" {
  type        = string
  default     = "/"
  description = "The path for the role and any created IAM policies"
}

variable "iam_role_policies" {
  type = list(object({
    key  = string
    json = string
  }))

  default     = []
  description = "A list of JSON IAM policy documents for this role"

  validation {
    condition = alltrue([for k in distinct(var.iam_role_policies[*].key) :
      can(regex("^[a-z][a-z0-9_-].*[a-z]$", k))
    ])
    error_message = "Keys must begin and end with a letter, and contain only lowercase letters and hyphens"
  }

  validation {
    condition     = length(var.iam_role_policies) == length(distinct(var.iam_role_policies[*].key))
    error_message = "Policy objects must have unique keys"
  }

}


variable "use_name_prefix" {
  type        = bool
  description = "Whether to use 'name' or 'name_prefix' when creating the role. Normally we should use name_prefix, but some resources such as AWS managed roles use the name, so we must name as well when managing those."
  default     = true
}

variable "iam_policy_document" {
  type        = string
  description = "A JSON-formatted policy document"
}

variable "iam_policy_description" {
  type        = string
  description = "A description of the policy"
}

variable "iam_policy_path" {
  type        = string
  default     = "/"
  description = "The path for the policy"
}

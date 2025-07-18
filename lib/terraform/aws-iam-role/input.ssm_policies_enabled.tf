variable "iam_role_ssm_policies_enabled" {
  type        = bool
  default     = false
  description = "Whether or not to add policies required for Systems Manager support"
}

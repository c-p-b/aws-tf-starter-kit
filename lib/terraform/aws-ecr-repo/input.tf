variable "aws_ecr_repo_enabled" {
  type    = bool
  default = false

  description = "Whether or not to enable this module"
}

variable "aws_ecr_repo_mutable_tags" {
  type        = bool
  default     = true
  description = "Whether or not tags should be mutable"
}

variable "aws_ecr_repo_encryption" {
  type = object({
    type        = string
    kms_key_arn = optional(string, null)
  })

  default = {
    type        = "KMS"
    kms_key_arn = ""
  }

  validation {
    condition = contains([
      "KMS",
      "AES256",
    ], var.aws_ecr_repo_encryption.type)

    error_message = "Encryption type must be one of [AES256, KMS]."
  }

  validation {
    condition = (
      var.aws_ecr_repo_encryption.type != "KMS"
      ? true
      : var.aws_ecr_repo_encryption.type != null
    )

    error_message = "An encryption type of KMS must also contain a KMS Key ARN."
  }
}

variable "aws_ecr_repo_policy_json" {
  type        = string
  default     = null
  description = "The resource-level policy to apply to the repository"
}

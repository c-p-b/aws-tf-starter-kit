variable "aws_bucket_enabled" {
  description = "Whether or not to create the resource"
  type        = bool
  default     = true
}

variable "aws_bucket_destruction_enabled" {
  description = "Whether or not to allow the bucket and all objects to be destroyed"
  type        = bool
  default     = false
}

variable "aws_bucket_object_ownership" {
  description = "The object ownership model for the resource"
  type        = string
  default     = "BucketOwnerEnforced"

  validation {
    condition = contains([
      "BucketOwnerEnforced",
      "BucketOwnerPreferred",
      "ObjectWriter",
    ], var.aws_bucket_object_ownership)
    error_message = "Must be one of [BucketOwnerEnforced, BucketOwnerPreferred, ObjectWriter]"
  }
}

variable "aws_bucket_versioning_enabled" {
  description = "Whether or not to enable versioning for objects"
  type        = bool
  default     = false
}

variable "aws_bucket_encryption_enabled" {
  description = "Whether or not to encrypt objects within the bucket"
  type        = bool
  default     = true
}

variable "aws_bucket_policy_json" {
  description = "A JSON policy document describing the bucket policy"
  type        = string
  default     = null
  nullable    = true
}

variable "aws_bucket_lifecycle_rules" {
  type = list(object({
    id      = optional(string)
    enabled = optional(bool, true)
    filter = object({
      prefix = optional(string)
      and = optional(object({
        object_size_greater_than = optional(number)
        object_size_less_than    = optional(number)
        prefix                   = optional(string)
        tags                     = optional(map(string))
      }))
      object_size_greater_than = optional(number)
      object_size_less_than    = optional(number)
      tag = optional(object({
        key   = string
        value = string
      }))
    })
    expiration = optional(object({
      date                         = optional(string)
      days                         = optional(number)
      expired_object_delete_marker = optional(bool)
    }))
    transition = optional(list(object({
      date          = optional(string)
      days          = optional(number)
      storage_class = string
    })))
    abort_incomplete_multipart_upload = optional(object({
      days_after_initiation = number
    }))
    noncurrent_version_expiration = optional(object({
      newer_noncurrent_versions = optional(number)
      noncurrent_days           = number
    }))
    noncurrent_version_transition = optional(list(object({
      newer_noncurrent_versions = optional(number)
      noncurrent_days           = number
      storage_class             = string
    })))
  }))

  default = []

  description = "A list of lifecycle policy rules, matching the aws_s3_bucket_lifecycle_configuration rule schema."

  validation {
    condition = alltrue([
      for rule in var.aws_bucket_lifecycle_rules : (
        length(coalesce(rule.transition, [])) +
        (rule.expiration != null ? 1 : 0) +
        (rule.noncurrent_version_expiration != null ? 1 : 0) +
        length(coalesce(rule.noncurrent_version_transition, [])) +
        (rule.abort_incomplete_multipart_upload != null ? 1 : 0)
    ) >= 1])
    error_message = "Each lifecycle rule must specify at least one of: transition, expiration, noncurrent_version_expiration, noncurrent_version_transition, or abort_incomplete_multipart_upload"
  }

  validation {
    condition = alltrue(flatten([
      for rule in var.aws_bucket_lifecycle_rules : [
        for transition in concat(
          coalesce(rule.transition, []),
          coalesce(rule.noncurrent_version_transition, [])
          ) : contains([
            "GLACIER",
            "STANDARD_IA",
            "ONEZONE_IA",
            "INTELLIGENT_TIERING",
            "DEEP_ARCHIVE",
            "GLACIER_IR"
        ], transition.storage_class)
      ]
    ]))
    error_message = "Storage class in transition must be one of: GLACIER, STANDARD_IA, ONEZONE_IA, INTELLIGENT_TIERING, DEEP_ARCHIVE, GLACIER_IR"
  }
}

variable "bucket_name_override" {
  description = "Sets the bucket attribute instead of the bucket prefix which is the default behavior."
  default     = false
  type        = bool
}

variable "server_side_encryption_algorithm" {
  description = ""
  default     = "aws:kms"
  type        = string

  validation {
    condition = contains([
      "aws:kms",
      "aws:kms:dsse",
      "AES256",
    ], var.server_side_encryption_algorithm)
    error_message = "Must be one of [aws:kms, aws:kms:dsse, AES256]"
  }
}

variable "bucket_key_enabled" {
  description = "When KMS encryption is used to encrypt new objects in this bucket, the bucket key reduces encryption costs by lowering calls to AWS KMS."
  default     = true
  type        = bool
}


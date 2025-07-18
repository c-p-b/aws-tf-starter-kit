variable "bucket_name" {
  description = "Name for the S3 bucket to store Terraform state. If not provided, a unique name will be generated."
  type        = string
  default     = ""
}

variable "table_name" {
  description = "Name for the DynamoDB table for state locking. Defaults to 'terraform-state-locks'."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
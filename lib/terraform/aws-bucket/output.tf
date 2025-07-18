output "arn" {
  value = length(aws_s3_bucket.this) > 0 ? one(aws_s3_bucket.this).arn : null
}

output "ro_policy_json" {
  value = length(data.aws_iam_policy_document.ro) > 0 ? one(data.aws_iam_policy_document.ro).json : null
}

output "rw_policy_json" {
  value = length(data.aws_iam_policy_document.rw) > 0 ? one(data.aws_iam_policy_document.rw).json : null
}

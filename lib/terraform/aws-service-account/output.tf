output "arn" {
  value       = try(aws_iam_user.this[0].arn, null)
  description = "The ARN of the service account"
}

output "name" {
  value       = try(aws_iam_user.this[0].name, null)
  description = "The name of the service account"
}

output "secret_key" {
  value     = aws_iam_access_key.this[0].secret
  sensitive = true
}

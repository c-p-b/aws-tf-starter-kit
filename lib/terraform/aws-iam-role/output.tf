output "arn" {
  value       = aws_iam_role.this.arn
  description = "The ARN of the IAM role"
}

output "name" {
  value       = aws_iam_role.this.name
  description = "The name of the IAM role"
}

output "instance_profile_name" {
  value = (
    var.iam_role_instance_profile_enabled == true
    ? aws_iam_instance_profile.this[0].name
    : ""
  )

  description = "The name of the instance profile, if enabled"
}

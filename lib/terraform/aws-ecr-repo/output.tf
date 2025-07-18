output "arn" {
  value = length(aws_ecr_repository.this) > 0 ? aws_ecr_repository.this[0].arn : null
}

output "url" {
  value = length(aws_ecr_repository.this) > 0 ? aws_ecr_repository.this[0].repository_url : null
}

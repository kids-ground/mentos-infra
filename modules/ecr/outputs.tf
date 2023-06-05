output "id" {
  value = aws_ecr_repository.ecr.registry_id
}

output "url" {
  value = aws_ecr_repository.ecr.repository_url
}

output "arn" {
  value = aws_ecr_repository.ecr.arn
}

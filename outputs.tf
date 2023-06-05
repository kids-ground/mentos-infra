output "ecr_repsitory_url" {
  value = module.ecr.url
}

output "ecr_id" {
  value = module.ecr.id
}

output "ecr_arn" {
  value = module.ecr.arn
}

output "route53_name_servers" {
  value = module.route53_zone.name_servers
}
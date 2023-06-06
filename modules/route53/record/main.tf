resource "aws_route53_record" "record" {
  name    = var.domain_name
  type    = var.record_type
  zone_id = var.hosted_zone_id

  alias {
    name                   = var.target_dns_name
    zone_id                = var.target_zone_id
    evaluate_target_health = false
  }
}

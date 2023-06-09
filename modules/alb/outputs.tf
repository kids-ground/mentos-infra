output "alb_id" {
  value = aws_alb.alb.id
}

output "target_group_id" {
  value = aws_alb_target_group.alb_target_group.id
}

output "target_group_arn" {
  value = aws_alb_target_group.alb_target_group.arn
}

output "alb_zone_id" {
  value = aws_alb.alb.zone_id
}

output "alb_dns_name" {
  value = aws_alb.alb.dns_name
}

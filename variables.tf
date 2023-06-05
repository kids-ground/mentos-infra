variable "project_name" {
  type = string
}
variable "domain_name" {
  type = string
}
variable "sub_domain" {
  type = string
}


variable "vpc_cidr" {
  type = string
}
variable "az_names" {
  type = list(string)
}
variable "public_subnets" { }
variable "private_subnets" { }
variable "alb_inbound_rule" { }
variable "ecs_inbound_rule" { }
variable "db_inbound_rule" { }
variable "outbound_rule" { }
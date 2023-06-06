variable "project_name" {
  type = string
}
variable "domain_name" { }
variable "sub_domain" { }
variable "api_server_domain" { }


variable "vpc_cidr" {
  type = string
}
variable "az_names" { }

variable "public_subnets" { }
variable "private_subnets" { }

variable "alb_inbound_rule" { }
# variable "ecs_service_inbound_rule" { }
# variable "ecs_instance_inbound_rule" { }
variable "db_inbound_rule" { }
variable "outbound_rule" { }
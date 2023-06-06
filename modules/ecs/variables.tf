variable "name" { }
variable "tags" { }
variable "ecr_url" { }
variable "cloudwatch_log_group_name" { }

variable "container_name" { }
variable "container_port" { }
variable "host_port" { }

variable "subnet_ids" { }
variable "instance_security_group_id" { }
variable "ecs_service_security_group_id" { }
variable "key_pair_name" { }
variable "alb_target_group_arn" { }
locals {
  alb_port_forward = 80
}


# VPC
module "vpc_main" {
  source = "./modules/vpc"
  name = var.project_name

  cidr = var.vpc_cidr
  public_subnets = var.public_subnets
  private_subnets = var.private_subnets
  az_names = var.az_names

  tags = {}
}

# ECR
module "ecr" {
  source = "./modules/ecr"
  name = var.project_name
}

# Route53 - Hosted Zone
module "route53_zone" {
  source = "./modules/route53/zone"
  name = var.domain_name
}

# ACM
module "acm" {
  source = "./modules/acm"
  domain_name = var.sub_domain
}

# ALB - SG, DNS
module "alb_sg" {
  source = "./modules/security_group"
  name = var.project_name
  vpc_id = module.vpc_main.vpc_id
  inbound_rule = var.alb_inbound_rule
  outbound_rule = var.outbound_rule
}

module "alb" {
  source = "./modules/alb"
  name = var.project_name
  tags = {}
  forwarding_port = local.alb_port_forward

  acm_arn = module.acm.arn
  vpc_id = module.vpc_main.vpc_id
  security_group_id = module.alb_sg.id
  subnet_ids = module.vpc_main.public_subnets_ids
}

module "alb_dns" {
  source = "./modules/route53/record"
  domain_name = var.api_server_domain
  record_type = "A"
  hosted_zone_id = module.route53_zone.zone_id
  target_dns_name = module.alb.alb_dns_name
  target_zone_id = module.alb.alb_zone_id
}

# ECS - ALB 연결, sg(inbound - ALB sg, 22)
resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name = "${var.project_name}-ecs-cw"
}

module "ecs" {
  source = "./modules/ecs"
  name = var.project_name
  tags = {}

  ecr_url = module.ecr.url
  cloudwatch_log_group_name = aws_cloudwatch_log_group.ecs_log_group.name

  subnet_ids = module.vpc_main.public_subnets_ids
  instance_security_group_id = module.alb_sg.id
  ecs_service_security_group_id = module.alb_sg.id

  container_name = "${var.project_name}-ecs-container"
  container_port = local.alb_port_forward
  host_port = local.alb_port_forward

  key_pair_name = "${var.project_name}_key_pair"
  alb_target_group_arn = module.alb.target_group_arn

  depends_on = [ module.alb ]
}

module "ecs_instance_eip" {
  source = "./modules/eip"
  instance_id = module.ecs.ecs_instance_id
  depends_on = [ module.ecs ]
}


# RDS, sg


# S3, IAM
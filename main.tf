
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

# ALB - ACM등록, DNS등록, sg등록, target group등록


# ECS - ALB 연결, sg(inbound - ALB sg, 22)


# RDS, sg


# S3, IAM
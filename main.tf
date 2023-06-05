
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

# Route53

# ACM

# ALB - ACM, DNS, sg, target group


# ECS - ALB 연결, sg(inbound - ALB sg, 22)


# RDS, sg


# S3, IAM
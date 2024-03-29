locals {
  alb_port_forward = 80
  ecs_host_port = 0 # ECS가 포트 동적할당
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

# ECS - ALB 연결, sg(inbound - ALB sg)
locals {
  ecs_container_name = "${var.project_name}-ecs-container"
}

module "ecs_instance_sg" {
  source = "./modules/security_group"
  name = "${var.project_name}-ecs-instance-ec2-sg"
  vpc_id = module.vpc_main.vpc_id
  inbound_rule = var.ecs_instance_inbound_rule
  outbound_rule = var.outbound_rule
}

resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name = "${var.project_name}-ecs-cw"
  retention_in_days = 7
}

module "ecs" {
  source = "./modules/ecs"
  name = var.project_name
  tags = {}
  vpc_id = module.vpc_main.vpc_id

  ecr_url = module.ecr.url
  cloudwatch_log_group_name = aws_cloudwatch_log_group.ecs_log_group.name

  subnet_ids = module.vpc_main.public_subnets_ids
  instance_security_group_id = module.ecs_instance_sg.id

  container_name = local.ecs_container_name
  container_port = local.alb_port_forward
  host_port = local.ecs_host_port

  key_pair_name = "${var.project_name}_key_pair"
  alb_target_group_arn = module.alb.target_group_arn

  depends_on = [ module.alb ]
}

module "ecs_instance_eip" {
  source = "./modules/eip"
  instance_id = module.ecs.ecs_instance_id
  depends_on = [ module.ecs ]
}

# ECS - CodePipeLine Artifact bucket
resource "aws_s3_bucket" "codepipeline_bucket" {
  bucket = "${var.project_name}-codepipeline-bucket"
  force_destroy = true
}

# ECS - CodePipeLine 자동배포
locals {
  # 아티팩트를 저장할 S3 버킷의 하위디렉터리를 지정
  source_output_artifact_name = "source_output"
  build_output_artifact_name = "build_output"
}

module "codebuild" {
  source = "./modules/code_suite/code_build"
  name = var.project_name
  artifact_bucket_arn = aws_s3_bucket.codepipeline_bucket.arn
  container_name = local.ecs_container_name
  ecr_repo_uri = module.ecr.url

  ecs_cluster_name = module.ecs.ecs_cluster_name
  ecs_service_name = module.ecs.ecs_service_name
}

module "codepipeline_iam_role" {
  source = "./modules/code_suite/code_pipeline/iam"
  name = var.project_name
  artifact_bucket_arn = aws_s3_bucket.codepipeline_bucket.arn
  code_build_arn = module.codebuild.arn
  ecr_arn = module.ecr.arn
}

resource "aws_codepipeline" "codepipeline" {
  name = "${var.project_name}-code-pipeline"
  role_arn = module.codepipeline_iam_role.codepipeline_role_arn

  artifact_store {
    location = aws_s3_bucket.codepipeline_bucket.bucket
    type = "S3"
  }

  stage {
    name = "Source"
    action {
      name = "Source"
      category = "Source"
      owner = "AWS"
      provider = "ECR"
      version = "1"
      input_artifacts = [ ]
      # 해당 디렉터리에 imageDetail.json 파일이 저장
      output_artifacts = [ local.source_output_artifact_name ]
      configuration = {
        RepositoryName = "${module.ecr.repo_name}"
        ImageTag = "latest"
      }
    }
  }

  stage {
    name = "Build"
    action {
      name = "Build"
      category = "Build"
      owner = "AWS"
      provider = "CodeBuild"
      version = "1"
      input_artifacts = [local.source_output_artifact_name]
      output_artifacts = [local.build_output_artifact_name]
      # Code Build project 넣기
      configuration = {
        ProjectName = module.codebuild.id
      }
    }
  }

  # S3, ECR, ECS 로의 접근 권한 필요
  stage {
    name = "Deploy"
    action {
      name = "Deploy"
      category = "Deploy"
      owner = "AWS"
      provider = "ECS"
      version = "1"
      input_artifacts = [local.build_output_artifact_name]

      configuration = {
        ClusterName: module.ecs.ecs_cluster_name
        ServiceName: module.ecs.ecs_service_name
        FileName: "imagedefinitions.json"
      }
    }
  }
}

# EventBridge - CodePipleLine Trigger
module "eventbridge_codepipeline_role" {
  source = "./modules/event_bridge"
  name = var.project_name
  codepipeline_arn = aws_codepipeline.codepipeline.arn

  depends_on = [ aws_codepipeline.codepipeline ]
}

resource "aws_cloudwatch_event_rule" "ecr_push" {
  name = "${var.project_name}-trigger-event-rule"
  description = "ECR push Rule"
  event_pattern = <<EOF
{
  "detail-type": [
    "ECR Image Action"
  ],
  "source": [
    "aws.ecr"
  ],
  "detail": {
    "action-type": [
      "PUSH"
    ],
    "image-tag": [
      "latest"
    ],
    "repository-name": [
      "${module.ecr.repo_name}"
    ],
    "result": [
      "SUCCESS"
    ]
  }
}
EOF  
}

resource "aws_cloudwatch_event_target" "codepipeline" {
  rule = aws_cloudwatch_event_rule.ecr_push.name
  target_id = "DeployToECS"
  arn = aws_codepipeline.codepipeline.arn
  role_arn = module.eventbridge_codepipeline_role.eventbridge_codepipeline_role_arn
}


# RDS
module "rds_sg" {
  source = "./modules/security_group"
  name = "${var.project_name}-rds"
  vpc_id = module.vpc_main.vpc_id
  inbound_rule = var.db_inbound_rule
  outbound_rule = var.outbound_rule
}

module "db" {
  source = "./modules/rds"
  project_name = var.project_name

  db_subnet_ids = module.vpc_main.private_subnets_ids
  db_sg_id = module.rds_sg.id
  db_az_name = var.az_names[0]

  db_name = var.db_name
  db_username = var.db_username
  db_password = var.db_password
}

# S3 - Image bucket
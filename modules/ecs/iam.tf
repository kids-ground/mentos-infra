# ECS Conatiner Instance(ec2)의 role
# - 정책 부여(AmazonEC2ContainerServiceforEC2Role) - ECS, ECR 관련 권한 및 로그 기록 권한
#   - EC2에 존재하는 ECS 컨테이너 에이전트에서 클러스터 관련작업을 위해 필요
# - EC2 profile로 만들고 EC2 생성 시 넣어주기
resource "aws_iam_role" "ecs_instance_role" {
  name = "${var.name}-ecs-instance-role"
  path = "/"
  assume_role_policy = "${data.aws_iam_policy_document.ecs_instance_role.json}"
}

data "aws_iam_policy_document" "ecs_instance_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecs_instance_role_attachment" {
  role = "${aws_iam_role.ecs_instance_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs_instance_profile" {
  name = "ecs-instance-profile"
  path = "/"
  role = "${aws_iam_role.ecs_instance_role.id}"

  provisioner "local-exec" {
    command = "sleep 60"
  }
}



# ECS Container의 role (ecs Task Role)
# - 컨테이너 위에서 돌아가는 어플리케이션들에게 주는 권한
# - 어플리케이션 사용하는 리소스들(S3, SES, SQS 등)에 대한 접근권한
resource "aws_iam_role" "ecs_tasks_role" {
  name               = "${var.name}-ecs-task-role"
  assume_role_policy = "${data.aws_iam_policy_document.ecs_tasks_role.json}"
}

data "aws_iam_policy_document" "ecs_tasks_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "ecs_tasks_policy" {
  name = "${var.name}-ecs-task-policy"
  path = "/"
  policy = data.aws_iam_policy_document.ecs_tasks_policy.json
}

data "aws_iam_policy_document" "ecs_tasks_policy" {
  statement {
    actions = [
      "ecr:*"
    ]
    effect = "Allow"
    resources = ["arn:aws:ecr:*"]
  }
}

resource "aws_iam_role_policy_attachment" "ecs_tasks_role_attachment" {
  role = aws_iam_role.ecs_tasks_role.name
  policy_arn = aws_iam_policy.ecs_tasks_policy.arn
}



# ECS Agent의 role (ecs Task Execution Role)
# - 컨테이너 인스턴스에서 돌아가는 ECS Agent, Docker Daemon에게 주는 권한 
# - ECR로부터 이미지를 받아오고 CloudWatch에 로그를 찍기 등에 대한 접근권한
resource "aws_iam_role" "ecs_tasks_execution_role" {
  name               = "${var.name}-ecs-execution-role"
  assume_role_policy = "${data.aws_iam_policy_document.ecs_tasks_execution_role.json}"
}

data "aws_iam_policy_document" "ecs_tasks_execution_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecs_tasks_execution_role_attachment" {
  role       = "${aws_iam_role.ecs_tasks_execution_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}



# ECS Service의 role
# - 정책(AmazonEC2ContainerServiceRole) - EC2, ALB 접근 관련 권한
# - 컨테이너를 동적으로 로드밸랜서와 매핑, 해제 하기 위해 필요
resource "aws_iam_role" "ecs_service_role" {
  name = "${var.name}-ecs-service-role"
  path = "/"
  assume_role_policy = "${data.aws_iam_policy_document.ecs_service_role.json}"
}

data "aws_iam_policy_document" "ecs_service_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = ["ecs.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecs_service_role_attachment" {
  role = "${aws_iam_role.ecs_service_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole"
}



# ECS AutoScaling target의 role
# - 정책(AmazonEC2ContainerServiceAutoscaleRole) - ECS 내 인스턴스 오토스케일 접근 권한
resource "aws_iam_role" "ecs_autoscale_role" {
  name = "${var.name}-ecs-autoscale-role"
  path = "/"
  assume_role_policy = data.aws_iam_policy_document.ecs_autoscale_role.json
}

data "aws_iam_policy_document" "ecs_autoscale_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = ["application-autoscaling.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecs_autoscale_role_attachment" {
  role = aws_iam_role.ecs_autoscale_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceAutoscaleRole"
}
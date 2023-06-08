
# ECS Cluster
resource "aws_ecs_cluster" "ecs_cluster" {
  name = "${var.name}-ecs-cluster"
}

# ECS instance
resource "aws_key_pair" "key_pair" {
  key_name   = "${var.key_pair_name}"
  public_key = file("~/.ssh/${var.key_pair_name}.pub")
}

resource "aws_instance" "ec2" {
  ami = "ami-0e4a9ad2eb120e054" # Amazon Linux2 ami(ap-northeast-2)
  instance_type = "t2.micro" # 프리티어

  subnet_id = var.subnet_ids[0]
  vpc_security_group_ids = [ var.instance_security_group_id ]
  iam_instance_profile = aws_iam_instance_profile.ecs_instance_profile.name

  user_data = file("${path.module}/ec2_user_data/user_data.sh")
  key_name = aws_key_pair.key_pair.key_name

  tags = merge(
    {
      Name = format(
        "%s-public-ecs-instance",
        var.name
      )
    },
    var.tags,
  )

  depends_on = [ aws_ecs_cluster.ecs_cluster ]
}

# ECS Task Definition - 최초 태스크 정의
resource "aws_ecs_task_definition" "task_definition" {
  family = "${var.name}-ecs-task-definition"
  container_definitions = jsonencode([
    {
      "name": "${var.container_name}",
      "image": "${var.ecr_url}:latest",
      "essential": true,
      "portMappings": [
        {
          "containerPort": var.container_port,
          "hostPort": var.host_port
        }
      ],
      "memory": 512,
      "cpu": 512, # 1024 == 1vCPU
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "${var.cloudwatch_log_group_name}",
          "awslogs-region": "ap-northeast-2",
          "awslogs-stream-prefix": "ecs"
        }
      }
    }
  ])

  task_role_arn = aws_iam_role.ecs_tasks_role.arn # 컨테이너의 어플리케이션의 접근수준(ex. 어플리케이션이 SNS에 접근하는 등의 역할)
  execution_role_arn = aws_iam_role.ecs_tasks_execution_role.arn # 컨테이너 인스턴스에 존재하는 ECS Agent의 접근수준(ex. ECR에서 이미지 받아오기, CloudWatch로 로그보내기 등)

  network_mode = "awsvpc"
  requires_compatibilities = ["EC2"]
  memory = 512
  cpu = 512

  depends_on = [ 
    aws_iam_role.ecs_tasks_role,
    aws_iam_role.ecs_tasks_execution_role
  ]
}

# ECS Service
resource "aws_ecs_service" "service" {
  name = "${var.name}-ecs-service"
  cluster = aws_ecs_cluster.ecs_cluster.id
  launch_type = "EC2"
  desired_count = 1

  task_definition = aws_ecs_task_definition.task_definition.arn
  
  load_balancer {
    target_group_arn = var.alb_target_group_arn # service와 연결할 ALB의 target group
    container_port = var.container_port # 연결될 컨테이너 포트번호
    container_name = "${var.container_name}"
  }

  network_configuration {
    security_groups = [ var.ecs_service_security_group_id ]
    subnets = var.subnet_ids
  }

  lifecycle {
    ignore_changes = [desired_count] # AutoScaling 가능하도록 무시가능하게 설정
  }
}

# ECS AutoScale - CloudWatch Alarm 사용
resource "aws_appautoscaling_target" "autoscale_target" {
  max_capacity = 2
  min_capacity = 1
  resource_id = "service/${aws_ecs_cluster.ecs_cluster.name}/${aws_ecs_service.service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
  role_arn = aws_iam_role.ecs_autoscale_role.arn
}

resource "aws_appautoscaling_policy" "autoscale_policy_cpu" {
  name               = "${var.name}-ecs-autoscale-policy-cpu"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.autoscale_target.resource_id
  scalable_dimension = aws_appautoscaling_target.autoscale_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.autoscale_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization" # 메모리 - "ECSServiceAverageMemoryUtilization"
    }
    target_value = 80
  }
  depends_on = [aws_appautoscaling_target.autoscale_target]
}
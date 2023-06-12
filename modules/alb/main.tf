resource "aws_alb" "alb" {
  load_balancer_type = "application"
  security_groups = [ 
    var.security_group_id
  ]
  subnets = var.subnet_ids

  # enable_deletion_protection = true
  tags = merge(
    {
      Name = format(
        "%s-alb",
        var.name,
      )
    },
    var.tags
  )
}

resource "aws_alb_listener" "https_listener" {
  load_balancer_arn = aws_alb.alb.arn
  certificate_arn = var.acm_arn
  port = 443
  protocol = "HTTPS"
  ssl_policy = "ELBSecurityPolicy-2016-08"

  default_action {
    type = "forward"
    target_group_arn = aws_alb_target_group.alb_target_group.arn
  }
}

resource "aws_alb_listener" "http_listener" {
  load_balancer_arn = aws_alb.alb.arn
  port = 80
  protocol = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port = 443
      protocol = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_alb_target_group" "alb_target_group" {
  name = "${var.name}-alb-target-group-2"
  vpc_id = var.vpc_id
  target_type = "instance"
  protocol = "HTTP"
  port = var.forwarding_port
  
  health_check {
    healthy_threshold   = "3"
    interval            = "10"
    port                = "traffic-port"
    path                = "/health-check"
    protocol            = "HTTP"
    unhealthy_threshold = "3"
  }

  lifecycle {
    create_before_destroy = false
  }
}
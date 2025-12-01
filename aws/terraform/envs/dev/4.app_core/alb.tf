locals {
  # Create a Short Name to avoid ALB's 32 character error
  # Ex: devops-social-scheduler-app -> social-app
  alb_name_prefix = "social-app"
}

resource "aws_lb" "main" {
  name               = "${local.alb_name_prefix}-${var.env}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = data.terraform_remote_state.general.outputs.public_subnet_ids
}

resource "aws_lb_target_group" "api" {
  name        = "${local.alb_name_prefix}-${var.env}-api-tg"
  port        = 8000
  protocol    = "HTTP"
  vpc_id      = data.terraform_remote_state.general.outputs.vpc_id
  target_type = "ip" # Force 'ip' for Fargate

  health_check {
    path                = "/health" # API must have this path to report "I'm alive"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api.arn
  }
}

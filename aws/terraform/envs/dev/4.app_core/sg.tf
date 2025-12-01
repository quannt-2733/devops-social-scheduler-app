# Security Groups for Application Core (Load Balancer) - Public
resource "aws_security_group" "alb" {
  name        = "${var.project}-${var.env}-alb-sg"
  description = "Allow HTTP inbound traffic"
  vpc_id      = data.terraform_remote_state.general.outputs.vpc_id

  ingress {
    description = "HTTP from Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group for ESC Service - Private
resource "aws_security_group" "ecs" {
  name        = "${var.project}-${var.env}-ecs-sg"
  description = "Allow traffic from ALB only"
  vpc_id      = data.terraform_remote_state.general.outputs.vpc_id

  ingress {
    description     = "HTTP from ALB"
    from_port       = 8000             # Suppose Python API runs on port 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id] # Only accept guests from ALB
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Let ECS go out and call Facebook/DB API
  }
}

# Security Group for Lambda Worker (Just go to the Internet to post)
resource "aws_security_group" "worker" {
  name        = "${var.project}-${var.env}-worker-sg"
  description = "Security Group for Lambda Worker"
  vpc_id      = data.terraform_remote_state.general.outputs.vpc_id

  # Ingress: This Lambda works by Pull mechanism from SQS so no one needs to call it -> No need for Ingress.
  # However, to comply with some VPC Endpoint standards (if used later), we can leave ingress blank or only allow internally.
  # Here, leaving Ingress blank is the safest.

  # Egress: Need to go out to the Internet (via NAT) to call Facebook/Twitter API
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

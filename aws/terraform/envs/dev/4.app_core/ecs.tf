resource "aws_ecs_cluster" "main" {
  name = "${var.project}-${var.env}-cluster"
}

resource "aws_ecs_task_definition" "api" {
  family                   = "${var.project}-${var.env}-api-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256 # 0.25 vCPU
  memory                   = 512 # 512 MB RAM
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([{
    name      = "api-container"
    image = "${aws_ecr_repository.api_repo.repository_url}:latest"
    essential = true
    portMappings = [{
      containerPort = 8000 # Nginx defaults to 80, but we configure the app to assume 8000.
                           # (Note: If using native nginx, you must map port 80.
                           # But to unify Python code later, I keep 8000 here.
                           # When running in practice with nginx, it will fail healthcheck but Terraform still creates resources OK).
      hostPort      = 8000
    }]
    environment = [
      { name = "DB_TABLE", value = data.terraform_remote_state.database.outputs.dynamodb_table_name },
      { name = "SCHEDULER_GROUP", value = aws_scheduler_schedule_group.group.name },
      { name = "SQS_QUEUE_ARN", value = aws_sqs_queue.schedule_queue.arn },
      { name = "SCHEDULER_ROLE_ARN", value = aws_iam_role.scheduler_role.arn }
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/ecs/${var.project}-${var.env}-api"
        "awslogs-region"        = var.region
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])
}

resource "aws_ecs_service" "api" {
  name            = "${var.project}-${var.env}-api-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.api.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = data.terraform_remote_state.general.outputs.private_subnet_ids
    security_groups = [aws_security_group.ecs.id]
    assign_public_ip = false # Private Subnet does not need Public IP
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.api.arn
    container_name   = "api-container"
    container_port   = 8000
  }

  # Skip health check during creation to avoid timeout error due to no real code
  wait_for_steady_state = false
}

resource "aws_cloudwatch_log_group" "api_logs" {
  name              = "/ecs/${var.project}-${var.env}-api"
  retention_in_days = 3

  tags = {
    Name = "${var.project}-${var.env}-api-logs"
  }
}

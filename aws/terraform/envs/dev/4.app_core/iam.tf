# ------------------------------------------------------------------------------
# ECS TASK EXECUTION ROLE (Permission for ECS to "start" the container)
# (Pull image from ECR, push log to CloudWatch)
# ------------------------------------------------------------------------------
resource "aws_iam_role" "ecs_execution_role" {
  name = "${var.project}-${var.env}-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

# Assign standard AWS permissions to the Execution Role
resource "aws_iam_role_policy_attachment" "ecs_execution_attachment" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ------------------------------------------------------------------------------
# ECS TASK ROLE (API Code Permissions while running)
# (Allowed to write to DynamoDB, call EventBridge)
# ------------------------------------------------------------------------------
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.project}-${var.env}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

# Private policy: Only allow writing to specific DynamoDB tables (Least Privilege)
resource "aws_iam_role_policy" "ecs_task_policy" {
  name = "${var.project}-${var.env}-ecs-task-policy"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem"
        ]
        # Get ARN from the state of the database module
        Resource = data.terraform_remote_state.database.outputs.dynamodb_table_arn
      },
      {
        Effect = "Allow"
        Action = ["scheduler:CreateSchedule"]
        Resource = "*" # EventBridge Scheduler needs permission to create schedules
      },
      {
        Effect = "Allow"
        Action = "iam:PassRole" # To give Scheduler permission to trigger Lambda/SQS later
        Resource = aws_iam_role.scheduler_role.arn
      }
    ]
  })
}

# ------------------------------------------------------------------------------
# LAMBDA WORKER ROLE
# (Permissions: Read SQS, Get Secret, Read DynamoDB, Write Log, Connect to VPC)
# ------------------------------------------------------------------------------
resource "aws_iam_role" "lambda_worker_role" {
  name = "${var.project}-${var.env}-lambda-worker-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

# Assign basic permissions for Lambda to run in VPC (Create ENI, Write Log)
resource "aws_iam_role_policy_attachment" "lambda_vpc_access" {
  role       = aws_iam_role.lambda_worker_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# Custom Policy: Posting Policy
resource "aws_iam_role_policy" "lambda_worker_policy" {
  name = "${var.project}-${var.env}-lambda-worker-policy"
  role = aws_iam_role.lambda_worker_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = ["secretsmanager:GetSecretValue"]
        Resource = data.terraform_remote_state.database.outputs.secrets_arn
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:Query"
        ]
        Resource = data.terraform_remote_state.database.outputs.dynamodb_table_arn
      }
    ]
  })
}

# ------------------------------------------------------------------------------
# EVENTBRIDGE SCHEDULER ROLE
# (Permission: Allows Scheduler to fire messages to SQS)
# ------------------------------------------------------------------------------

# This role has a Trust Policy that allows "scheduler.amazonaws.com" to use
resource "aws_iam_role" "scheduler_role" {
  name = "${var.project}-${var.env}-scheduler-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "scheduler.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Grants this Role permission to send messages to SQS
resource "aws_iam_role_policy" "scheduler_policy" {
  name = "${var.project}-${var.env}-scheduler-policy"
  role = aws_iam_role.scheduler_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage"
        ]
        # Only allow shooting in our own queue (Least Privilege)
        Resource = aws_sqs_queue.schedule_queue.arn
      }
    ]
  })
}

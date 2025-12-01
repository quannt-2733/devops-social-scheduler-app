# SQS Queue
resource "aws_sqs_queue" "schedule_queue" {
  name                       = "${var.project}-${var.env}-schedule-queue"
  visibility_timeout_seconds = 60
}

# Generate pseudocode for Lambda (Placeholder)
data "archive_file" "worker_zip" {
  type        = "zip"
  output_path = "${path.module}/worker.zip"
  source_file = "${path.module}/lambda_function.py"
}

# Lambda Function
resource "aws_lambda_function" "worker" {
  function_name = "${var.project}-${var.env}-worker"
  role          = aws_iam_role.lambda_worker_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"

  filename         = data.archive_file.worker_zip.output_path
  source_code_hash = data.archive_file.worker_zip.output_base64sha256

  vpc_config {
    subnet_ids         = data.terraform_remote_state.general.outputs.private_subnet_ids
    security_group_ids = [aws_security_group.worker.id]
  }

  environment {
    variables = {
      DB_TABLE = data.terraform_remote_state.database.outputs.dynamodb_table_name
      SECRET_ID = data.terraform_remote_state.database.outputs.secrets_arn
    }
  }
}

# Trigger Lambda when SQS message arrives
resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn = aws_sqs_queue.schedule_queue.arn
  function_name    = aws_lambda_function.worker.arn
  batch_size       = 1
}

# EventBridge Scheduler Group (Where schedules are stored)
resource "aws_scheduler_schedule_group" "group" {
  name = "${var.project}-${var.env}-schedule-group"
}

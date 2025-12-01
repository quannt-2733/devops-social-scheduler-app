locals {
  lambda_name    = data.terraform_remote_state.app_core.outputs.lambda_function_name
  sqs_name       = data.terraform_remote_state.app_core.outputs.sqs_queue_name
}

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project}-${var.env}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            [ "AWS/Lambda", "Invocations", "FunctionName", local.lambda_name, { label : "Total Runs" } ],
            [ ".", "Errors", ".", ".", { label : "Errors", color : "#d62728" } ]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.region
          title   = "Worker Performance (Success vs Failure)"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            [ "AWS/SQS", "ApproximateNumberOfMessagesVisible", "QueueName", local.sqs_name, { label : "Pending Messages" } ],
            [ ".", "NumberOfMessagesSent", ".", ".", { label : "Incoming from Scheduler" } ]
          ]
          view    = "timeSeries"
          region  = var.region
          title   = "Schedule & Queue Status"
          period  = 300
        }
      },
      {
        type = "text"
        x = 0
        y = 6
        width = 24
        height = 2
        properties = {
            markdown = "## Operational Status\nMonitor errors in Red. If 'Pending Messages' grows high, Worker is stuck."
        }
      }
    ]
  })
}

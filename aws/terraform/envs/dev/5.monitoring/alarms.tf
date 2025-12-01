resource "aws_cloudwatch_metric_alarm" "worker_errors" {
  alarm_name          = "${var.project}-${var.env}-worker-error-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Trigger when Lambda Worker fails to process a post"

  dimensions = {
    FunctionName = data.terraform_remote_state.app_core.outputs.lambda_function_name
  }
}

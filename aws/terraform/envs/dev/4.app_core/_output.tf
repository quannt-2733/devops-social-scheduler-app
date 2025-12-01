output "ecr_repository_url" {
  value = aws_ecr_repository.api_repo.repository_url
  description = "URL of the ECR repository for the API container image"
}

output "alb_dns_name" {
  description = "Domain name of the Load Balancer"
  value       = aws_lb.main.dns_name
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.main.name
  description = "Name of the ECS cluster"
}

output "ecs_service_name" {
  value = aws_ecs_service.api.name
  description = "Name of the ECS service"
}

output "lambda_function_name" {
  description = "Name of the Lambda Worker"
  value       = aws_lambda_function.worker.function_name
}

output "sqs_queue_name" {
  description = "Name of the SQS Queue"
  value       = aws_sqs_queue.schedule_queue.name
}

output "scheduler_group_name" {
  description = "Name of the EventBridge Scheduler Group"
  value       = aws_scheduler_schedule_group.group.name
}

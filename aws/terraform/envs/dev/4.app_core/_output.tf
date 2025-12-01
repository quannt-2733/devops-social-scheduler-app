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

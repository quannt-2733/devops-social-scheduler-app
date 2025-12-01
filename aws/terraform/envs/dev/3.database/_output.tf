output "dynamodb_table_name" {
  value = aws_dynamodb_table.posts.name
  description = "The name of the DynamoDB table for posts."
}

output "dynamodb_table_arn" {
  value = aws_dynamodb_table.posts.arn
  description = "The ARN of the DynamoDB table for posts."
}

output "secrets_arn" {
  value = aws_secretsmanager_secret.social_tokens.arn
  description = "The ARN of the Secrets Manager secret for social media API tokens."
}

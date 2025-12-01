# Create AWS Secrets Manager secret for social media API tokens
resource "aws_secretsmanager_secret" "social_tokens" {
  name        = "${var.project}/${var.env}/social-tokens"
  description = "Tokens for Facebook, Twitter, LinkedIn APIs"

  recovery_window_in_days = 7
}

# Create initial version of the secret with placeholder values
resource "aws_secretsmanager_secret_version" "initial" {
  secret_id     = aws_secretsmanager_secret.social_tokens.id
  secret_string = jsonencode({
    facebook_token = "CHANGE_ME_IN_CONSOLE"
    twitter_token  = "CHANGE_ME_IN_CONSOLE"
  })

  # Ignore changes so Terraform doesn't reset the password every time you run the apply
  lifecycle {
    ignore_changes = [secret_string]
  }
}

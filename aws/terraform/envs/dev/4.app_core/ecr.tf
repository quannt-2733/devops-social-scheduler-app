resource "aws_ecr_repository" "api_repo" {
  name                 = "${var.project}-${var.env}-api"
  image_tag_mutability = "MUTABLE"

  # Automatically scan for security vulnerabilities when pushing images (Security First)
  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${var.project}-${var.env}-api-repo"
  }
}

# Backend configuration + AWS connection
# Example: Backend S3, AWS provider
terraform {
  required_version = ">= 1.3.9"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }
  backend "s3" {
    profile        = "myproject-dev"                    # ← Từ mục 3: AWS CLI profile
    bucket         = "devops-social-scheduler-app-dev-iac-state"          # ← Từ mục 5: Tên S3 bucket
    key            = "1.general/terraform.dev.tfstate"  # ← Đường dẫn file state
    region         = "ap-northeast-1"                   # ← Region triển khai
    encrypt        = true                               # ← Luôn bật encryption
    kms_key_id     = "arn:aws:kms:ap-southeast-1:661075516353:key/9b837095-d2f7-4d05-9d8b-a724f1fe86a9"  # ← KMS Key ARN
    dynamodb_table = "devops-social-scheduler-app-dev-terraform-state-lock"  # ← DynamoDB table
  }
}

provider "aws" {
  region  = var.region                    # ← Sử dụng biến từ tfvars
  profile = "${var.project}-${var.env}"   # ← Tự động tạo profile name
  default_tags {
    tags = {
      Project     = var.project          # ← Tag tự động cho tất cả resources
      Environment = var.env              # ← Tag môi trường
    }
  }
}

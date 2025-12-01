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
    profile        = "myproject-dev"
    bucket         = "devops-social-scheduler-app-dev-iac-state"
    key            = "3.database/terraform.dev.tfstate"
    region         = "ap-southeast-1"
    encrypt        = true
    kms_key_id     = "arn:aws:kms:ap-southeast-1:661075516353:key/9b837095-d2f7-4d05-9d8b-a724f1fe86a9"
    dynamodb_table = "devops-social-scheduler-app-dev-terraform-state-lock"
  }
}

provider "aws" {
  region  = var.region
  #profile = "${var.project}-${var.env}"
  profile = "myproject-dev"
  default_tags {
    tags = {
      Project     = var.project
      Environment = var.env
    }
  }
}

# Read remote state from general layer
data "terraform_remote_state" "general" {
  backend = "s3"
  config = {
    profile = "myproject-dev"
    bucket  = "devops-social-scheduler-app-dev-iac-state"
    key     = "1.general/terraform.dev.tfstate"
    region  = "ap-southeast-1"
  }
}

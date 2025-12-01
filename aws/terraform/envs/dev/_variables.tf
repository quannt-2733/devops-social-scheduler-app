variable "project" {
  description = "Name of project"
  type        = string
  default     = "devops-social-scheduler-app"
}

variable "env" {
  description = "Environment (dev/stg/prod)"
  type        = string
  default     = "dev"
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

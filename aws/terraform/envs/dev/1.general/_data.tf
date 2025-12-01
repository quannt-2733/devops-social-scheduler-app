# GET available information from AWS
# Ex: VPC ID, Subnet IDs, Security Group IDs, etc.
data "aws_availability_zones" "available" {
  state = "available"
}

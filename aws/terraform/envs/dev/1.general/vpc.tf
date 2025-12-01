# CREATE VPC và network resources
# Ex: VPC, Subnets, Internet Gateway, Route Tables, etc.
# Create VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project}-${var.env}-vpc"
  }
}

# Create Internet Gateway (IGW) for Public Subnets
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project}-${var.env}-igw"
  }
}

# Create Public Subnets (2 AZs) - For ALB, NAT Gateway
resource "aws_subnet" "public" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  # Split CIDR: For example VPC 10.0.0.0/16 -> Public 10.0.1.0/24, 10.0.2.0/24
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project}-${var.env}-public-subnet-${count.index + 1}"
    Tier = "Public"
  }
}

# Create Private Subnets (2 AZs) - For ECS, Lambda, DB (Highest Security)
resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  # Split CIDR: Private 10.0.10.0/24, 10.0.11.0/24 (Offset 10 to avoid overlap with Public)
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 10)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.project}-${var.env}-private-subnet-${count.index + 1}"
    Tier = "Private"
  }
}

# Route Table for Public Subnets (Direct Internet Access via IGW)
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project}-${var.env}-public-rt"
  }
}

# Assign Public Subnets to Public Route Table
resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

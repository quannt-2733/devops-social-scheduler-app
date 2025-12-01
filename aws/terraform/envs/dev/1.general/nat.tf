# Create Elastic IP (Static IP) for NAT Gateway
resource "aws_eip" "nat" {
  tags = {
    Name = "${var.project}-${var.env}-nat-eip"
  }
}

# Create NAT Gateway (Located in the first Public Subnet)
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name = "${var.project}-${var.env}-nat-gw"
  }

  # Wait for IGW to finish creating before creating NAT to avoid dependency errors
  depends_on = [aws_internet_gateway.main]
}

# Route Table for Private Subnet (Passing through NAT GW)
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name = "${var.project}-${var.env}-private-rt"
  }
}

# Assign Private Subnet to Private Route Table
resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

#
# VPC Resources
#  * VPC
#  * Subnets
#  * Internet Gateway
#  * Route Table
#
# Using these data sources allows the configuration to be
# generic for any region.
data "aws_region" "current" {}

data "aws_availability_zones" "available" {}

resource "aws_vpc" "rag-demo" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = var.name
    "kubernetes.io/cluster/${random_string.demo_suffix.result}-eks" = "shared"
  }
}

resource "aws_subnet" "rag-demo" {
  count = 2

  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = "10.0.${count.index}.0/24"
  vpc_id            = aws_vpc.rag-demo.id
  map_public_ip_on_launch = true  
  tags = {
    "Name" = "terraform-rag-demo-node"
    "kubernetes.io/cluster/${random_string.demo_suffix.result}-eks" = "shared"
  }
}

resource "aws_internet_gateway" "demo" {
  vpc_id = aws_vpc.rag-demo.id

  tags = {
    Name = "rag-demo"
  }
}

resource "aws_route_table" "demo" {
  vpc_id = aws_vpc.rag-demo.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.demo.id
  }
}

resource "aws_route_table_association" "demo" {
  count = 2

  subnet_id      = aws_subnet.rag-demo.*.id[count.index]
  route_table_id = aws_route_table.demo.id
}
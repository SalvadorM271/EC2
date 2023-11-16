provider "aws" {
  region = "us-east-1"
}

terraform {

  required_version = ">= 1.3.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
    
  }

}

// vpc

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "main"
    Environment = var.environment
  }
}

//igw

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "igw"
    Environment = var.environment
  }
}

// subnets

resource "aws_subnet" "private-us-east-1a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.0.0/18"
  availability_zone = "us-east-1a"

  tags = {
    Name = "test-EC2-private-us-east-1a"
    Environment = var.environment
  }
}

resource "aws_subnet" "private-us-east-1b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.32.0/18"
  availability_zone = "us-east-1b"

  tags = {
    Name = "test-EC2-private-us-east-1b"
    Environment = var.environment
  }
}

resource "aws_subnet" "public-us-east-1a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.64.0/18"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "test-EC2-public-us-east-1a"
    Environment = var.environment
  }
}

resource "aws_subnet" "public-us-east-1b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.96.0/18"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "test-EC2-public-us-east-1b"
    Environment = var.environment
  }
}

// eip and NAT (just one since is just for testing)

resource "aws_eip" "nat" {
  vpc = true

  tags = {
    Name = "eip"
    Environment = var.environment
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public-us-east-1a.id

  tags = {
    Name = "nat"
    Environment = var.environment
  }

  depends_on = [aws_internet_gateway.igw]
}

// route table for public subnet

resource "aws_route_table" "table_public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Environment = var.environment
  }
}

resource "aws_route" "route_public" {
  route_table_id         = aws_route_table.table_public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "route_association_public" {
  subnet_id      = var.subnet_id
  route_table_id = aws_route_table.table_public.id
}

// route table for private subnet

resource "aws_route_table" "table_private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Environment = var.environment
  }
}

resource "aws_route" "route_private" {
  route_table_id         = aws_route_table.table_private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

resource "aws_route_table_association" "route_association_private" {
  subnet_id      = var.subnet_id
  route_table_id = aws_route_table.table_private.id
}

// EC2 lauch template


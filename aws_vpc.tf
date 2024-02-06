# Terraform Configuration

locals {
  terraform_version = "1.7.2"
}

provider "aws" {
  region = "us-east-2"
}

resource "aws_vpc" "my_vpc" {
  cidr_block            = "10.0.0.0/16"
  enable_dns_support    = true
  enable_dns_hostnames  = true

  tags = {
    Name = "YatishVPC"
  }
}

resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "YatishIGW"
  }
}

resource "aws_route_table" "my_public_route" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }

  tags = {
    Name = "YatishPublicRouteTable"
  }
}

resource "aws_subnet" "my_public_subnet" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "YatishPublicSubnet"
  }
}

resource "aws_security_group" "my_security_group" {
  name        = "YatishSecurityGroup"
  description = "Allow SSH traffic from my public IP"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "my_ec2_instance" {
  ami                          = "ami-0866a04d72a1f5479"
  instance_type                = "t2.micro"
  key_name                     = "SampleKey"
  vpc_security_group_ids       = [aws_security_group.my_security_group.id]
  subnet_id                    = aws_subnet.my_public_subnet.id
  associate_public_ip_address  = true

  tags = {
    Name = "YatishEC2Instance"
  }
}

resource "aws_route_table_association" "my_subnet_association" {
  subnet_id      = aws_subnet.my_public_subnet.id
  route_table_id = aws_route_table.my_public_route.id

  depends_on = [
    aws_vpc.my_vpc,
    aws_subnet.my_public_subnet,
    aws_security_group.my_security_group,
  ]
}
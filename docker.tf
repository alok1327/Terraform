provider "aws" {
region = "ap-south-1"
}

resource "aws_vpc" "terraform_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "terraform_vpc"
  }
}

resource "aws_subnet" "terraform_public_subnet" {
  vpc_id            = aws_vpc.terraform_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "terraform Public Subnet"
  }
}

resource "aws_subnet" "terraform_private_subnet" {
  vpc_id            = aws_vpc.terraform_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "terraform Private Subnet"
  }
}

resource "aws_internet_gateway" "tf_ig" {
  vpc_id = aws_vpc.terraform_vpc.id

  tags = {
    Name = "tf Internet Gateway"
  }
}

resource "aws_route_table" "tf_public_rt" {
  vpc_id = aws_vpc.terraform_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.tf_ig.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.tf_ig.id
  }

  tags = {
    Name = "Public Route Table"
  }
}

resource "aws_route_table_association" "tf_public_rt" {
  subnet_id      = aws_subnet.terraform_public_subnet.id
  route_table_id = aws_route_table.tf_public_rt.id
}

resource "aws_security_group" "web_sg" {
  name   = "HTTP and SSH and HTTPS"
  vpc_id = aws_vpc.terraform_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
     from_port = 443
     to_port = 443
     protocol = "tcp"
     cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "web_instance" {
  ami           = "ami-06f621d90fa29f6d0"
  instance_type = "t2.micro"

  subnet_id                   = aws_subnet.terraform_public_subnet.id
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  associate_public_ip_address = true

  user_data = <<-EOF
  #!/bin/bash
  sudo yum update -y
  sudo yum install -y docker
  sudo service docker start
  sudo usermod -a -G docker ec2-user
  sudo docker pull nginx:latest
  sudo docker run --name mynginx1 -p 80:80 -d nginx 

EOF

   tags = {
    Name = "cloud"
  }
  
}

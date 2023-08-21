provider "aws" {
  region  = "us-west-2"
}

resource "aws_vpc" "wo_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "wo VPC"
  }
}

resource "aws_subnet" "wo_public_subnet" {
  vpc_id            = aws_vpc.wo_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-west-2a"

  tags = {
    Name = "wo Public Subnet"
  }
}

resource "aws_subnet" "wo_private_subnet" {
  vpc_id            = aws_vpc.wo_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-west-2b"

  tags = {
    Name = "wo Private Subnet"
  }
}

resource "aws_internet_gateway" "wo_ig" {
  vpc_id = aws_vpc.wo_vpc.id

  tags = {
    Name = "wo Internet Gateway"
  }
}

resource "aws_route_table" "wo_public_rt" {
  vpc_id = aws_vpc.wo_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.wo_ig.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.wo_ig.id
  }

  tags = {
    Name = "wo Public Route Table"
  }
}

resource "aws_route_table_association" "wo_public_1_rt_a" {
  subnet_id      = aws_subnet.wo_public_subnet.id
  route_table_id = aws_route_table.wo_public_rt.id
}

resource "aws_security_group" "wo_sg" {
  name   = "HTTP and SSH"
  vpc_id = aws_vpc.wo_vpc.id

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

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "web_instance" {
  ami           = "ami-0d593311db5abb72b"
  instance_type = "t2.micro"
  key_name      = "nonprod-FInca360"

  subnet_id                   = aws_subnet.wo_public_subnet.id
  vpc_security_group_ids      = [aws_security_group.wo_sg.id]
  associate_public_ip_address = true

  user_data = <<-EOF
  #!/bin/bash -ex

  amazon-linux-extras install nginx1 -y
  echo "<h1>$(curl https://api.kanye.rest/?format=text)</h1>" >  /usr/share/nginx/html/index.html 
  systemctl enable nginx
  systemctl start nginx
  EOF

  tags = {
    "Name" : "wo"
  }
}

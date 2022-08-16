resource "aws_vpc" "ayo_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "dev"
  }
}

resource "aws_subnet" "ayo_public_subnet" {
  vpc_id                  = aws_vpc.ayo_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"
  tags = {
    Name = "dev-public"
  }
}

resource "aws_internet_gateway" "ayo_internet_gateway" {
  vpc_id = aws_vpc.ayo_vpc.id

  tags = {
    Name = "dev.igw"
  }
}

resource "aws_route_table" "ayo_public_rt" {
  vpc_id = aws_vpc.ayo_vpc.id
  tags = {
    Name = "dev_public_rt"
  }
}

resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.ayo_public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.ayo_internet_gateway.id
}

resource "aws_route_table_association" "ayo_public_assoc" {
  subnet_id      = aws_subnet.ayo_public_subnet.id
  route_table_id = aws_route_table.ayo_public_rt.id
}

resource "aws_security_group" "ayo_sg" {
  name        = "dev.tags"
  description = "dev security group"
  vpc_id      = aws_vpc.ayo_vpc.id

  ingress {
    description = "TLS from VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["86.188.171.139/32"]

  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }

  tags = {
    Name = "dev.sg"
  }
}

resource "aws_key_pair" "ayo_auth" {
  key_name   = "ayokey"
  public_key = file("~/.ssh/id_rsa.pub")
}

resource "aws_instance" "dev_node" {
  ami                    = data.aws_ami.server_ami.id
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.ayo_auth.id
  vpc_security_group_ids = [aws_security_group.ayo_sg.id]
  subnet_id              = aws_subnet.ayo_public_subnet.id
  user_data              = file("userdata.tpl")
  root_block_device {
    volume_size = 10
  }
  tags = {
    "Name" = "dev-mode"
  }
}

















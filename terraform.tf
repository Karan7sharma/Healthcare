# VPC
resource "aws_vpc" "project-vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "project-vpc"
  }
}

# Subnet
resource "aws_subnet" "project-subnet" {
  vpc_id            = aws_vpc.project-vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "project-subnet"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "project-gw" {
  vpc_id = aws_vpc.project-vpc.id

  tags = {
    Name = "project-gw"
  }
}

# Route Table and Association
resource "aws_route_table" "project-rt" {
  vpc_id = aws_vpc.project-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.project-gw.id
  }

  tags = {
    Name = "project-rt"
  }
}

resource "aws_route_table_association" "project-rta" {
  subnet_id      = aws_subnet.project-subnet.id
  route_table_id = aws_route_table.project-rt.id
}

# Security Group
resource "aws_security_group" "project-sg" {
  name        = "project-sg"
  description = "Allow SSH and HTTP"
  vpc_id      = aws_vpc.project-vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "project-sg"
  }
}

# EC2 Instance 1 (20GB root volume + Elastic IP)
resource "aws_instance" "Master-Machine" {
  ami                         = "ami-0f918f7e67a3323f0" 
  instance_type               = "t3.medium"
  subnet_id                   = aws_subnet.project-subnet.id
  key_name                    = "project-keypair"
  vpc_security_group_ids      = [aws_security_group.project-sg.id]
  associate_public_ip_address = true

  root_block_device {
    volume_size = 20
    volume_type = "gp2"
  }

  tags = {
    Name = "Master-Machine"
  }
}


resource "aws_eip" "master-eip" {
  instance = aws_instance.Master-Machine.id

  depends_on = [aws_internet_gateway.project-gw]
}

# EC2 Instance 2
resource "aws_instance" "Worker-Node" {
  ami                         = "ami-0f918f7e67a3323f0"
  instance_type               = "t3.medium"
  subnet_id                   = aws_subnet.project-subnet.id
  key_name                    = "project-keypair"
  vpc_security_group_ids      = [aws_security_group.project-sg.id]
  associate_public_ip_address = true

  tags = {
    Name = "Worker Node"
  }
}

# EC2 Instance 3
resource "aws_instance" "Monitoring" {
  ami                         = "ami-0f918f7e67a3323f0"
  instance_type               = "t3.medium"
  subnet_id                   = aws_subnet.project-subnet.id
  key_name                    = "project-keypair"
  vpc_security_group_ids      = [aws_security_group.project-sg.id]
  associate_public_ip_address = true

  tags = {
    Name = "Prometheus & Grafana"
  }
}

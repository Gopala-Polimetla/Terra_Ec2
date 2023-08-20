provider "aws" {
  region = var.region
}

variable "region" {}
variable "vpc_cidr_block" {}
variable "environment" {}
variable "Subnet_cidr_block" {}
variable "public_key_location" {}

resource "aws_vpc" "Demo_VPC" {
  cidr_block = var.vpc_cidr_block
  tags = {
     Name = "${var.environment}-VPC"
   }
}

resource "aws_subnet" "Demo_subnet" {
  vpc_id = aws_vpc.Demo_VPC.id
  cidr_block = var.Subnet_cidr_block
  tags = {
     Name = "${var.environment}-Subnet"
   }
}

resource "aws_internet_gateway" "Demo_IGW" {
  vpc_id = aws_vpc.Demo_VPC.id
  tags = {
     Name = "${var.environment}-IGW"
   }
}

resource "aws_route_table" "Demo_RT" {
  vpc_id = aws_vpc.Demo_VPC.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.Demo_IGW.id
  }
  tags = {
     Name = "${var.environment}-RT"
   }
}

resource "aws_route_table_association" "Demo_Rt_Association" {
  subnet_id = aws_subnet.Demo_subnet.id
  route_table_id = aws_route_table.Demo_RT.id
}

output "Subnet_CIDR_BLOCK" {
  value = aws_subnet.Demo_subnet.cidr_block
}

output "VPC_Details" {
  value = aws_vpc.Demo_VPC.cidr_block
}

data "aws_ami" "amazon_linux_latest" {
  most_recent = "true"
  owners = ["amazon"]
  filter {
    name = "name"
    values = ["amzn2-ami-*-x86_64-gp2"]
  }
  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
}

output "AMI_ID_Details" {
    value = data.aws_ami.amazon_linux_latest.id
}

resource "aws_key_pair" "My_KP" {
  key_name = "My_Key"
  public_key = file(var.public_key_location)
}

resource "aws_instance" "Demo_EC2_Instance" {
  ami = data.aws_ami.amazon_linux_latest.id
  subnet_id = aws_subnet.Demo_subnet.id
  instance_type = "t2.micro"
  associate_public_ip_address = "true"
  key_name = aws_key_pair.My_KP.key_name
  security_groups = [aws_security_group.My-Demo-SG.id]
  tags = {
     Name = "${var.environment}-EC2-Instance"
   }
    user_data = <<-EOF
                    #!/bin/bash
                    echo "Hello from user_data script" > /tmp/user_data_output.txt
                    yum install git -y
                EOF
}

output "Public_IP" {
  value = aws_instance.Demo_EC2_Instance.public_ip
}

resource "aws_security_group" "My-Demo-SG" {
  name = "My_Demo_SG"
  vpc_id = aws_vpc.Demo_VPC.id

  tags = {
    Name = "Demo_SG"
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}
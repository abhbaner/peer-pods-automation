# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
  access_key = var.aws_access_key_id
  secret_key = var.aws_secret_key_id
}


resource "aws_vpc" "peerpod_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "peer-pod-vpc"
  }
}


resource "aws_subnet" "peerpod_subnet" {
  vpc_id     = aws_vpc.peerpod_vpc.id
  cidr_block = "10.0.0.0/24"
  availability_zone = "us-west-2b"
  map_public_ip_on_launch = true
  tags = {
    Name = "peer-pod-subnet"
  }
}


resource "aws_internet_gateway" "peerpod_igw" {
  vpc_id = aws_vpc.peerpod_vpc.id
  tags = {
    Name = "peer-pod-igw"
  }
}


resource "aws_route_table" "peerpod_rt" {
  vpc_id = aws_vpc.peerpod_vpc.id
  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.peerpod_igw.id
  }

  route {
    cidr_block        = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.peerpod_igw.id
  }

  tags = {
    Name = "peer-pod-routeTable"
  }
} 

 #associating route table with IGW and subnet
 resource "aws_route_table_association" "rt_assoc_subnet" {
  subnet_id      = aws_subnet.peerpod_subnet.id
  route_table_id = aws_route_table.peerpod_rt.id
  }


resource "aws_security_group" "peerpod_sg" {
  name        = "peerpod_sg"
  description = "Allow ssh inbound traffic"
  vpc_id      = aws_vpc.peerpod_vpc.id

  ingress {
    description = "ingress rule for ssh access"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    }

  egress {
    description = "egress rule for internet access"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    }

  tags = {
    Name = "peer-pod-sg"
  }

}

#Creates an Ubuntu 20.04 instance
resource "aws_instance" "peer-pods-ec2"{
  ami = "ami-0fc231e7d7af4036b"
  instance_type = "t2.2xlarge"
  key_name = var.ec2_ssh_key_name
  subnet_id = aws_subnet.peerpod_subnet.id
  availability_zone = "us-west-2b"
  vpc_security_group_ids = [aws_security_group.peerpod_sg.id]
  root_block_device {
    volume_size           = "30"
    volume_type           = "gp2"
    encrypted             = false
    delete_on_termination = true
  }
  user_data = <<-EOF
              #!/bin/bash
              wget https://raw.githubusercontent.com/abhbaner/peer-pods-automation/master/setup.sh -P /home/ubuntu/
              chmod +x /home/ubuntu/setup.sh
              EOF
  tags = {
    Name = "peer-pods-ec2"
  }

}

output "instance_public_ips" {
  value = aws_instance.peer-pods-ec2.public_ip
}

output "ec2_instance_id" {
  value = aws_instance.peer-pods-ec2.id
}


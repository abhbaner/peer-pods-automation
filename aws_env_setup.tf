# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
  access_key = var.aws_access_key_id
  secret_key = var.aws_secret_key_id
}

#resource creation general syntac
#resource "<provider>_<resource_type>" "name"{
#    key = value
#    key2 = value2
#}

# Create a VPC
resource "aws_vpc" "peerpod_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "peer-pod-vpc"
  }
}

#Create a subnet
resource "aws_subnet" "peerpod_subnet" {
  vpc_id     = aws_vpc.peerpod_vpc.id
  cidr_block = "10.0.0.0/24"
  availability_zone = "us-west-2b"
  map_public_ip_on_launch = true
  tags = {
    Name = "peer-pod-subnet"
  }
}

#Create an Internet gateway + attach to VPC
resource "aws_internet_gateway" "peerpod_igw" {
  vpc_id = aws_vpc.peerpod_vpc.id
  tags = {
    Name = "peer-pod-igw"
  }
}

#attaching VPC to igwq
#resource "aws_internet_gateway_attachment" "attachVpcToGw" {
#  internet_gateway_id = aws_internet_gateway.peerpod_igw.id
#  vpc_id              = aws_vpc.peerpod_vpc.id
#}

#Create a route table
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




#Create security group
resource "aws_security_group" "peerpod_sg" {
  name        = "peerpod_sg"
  description = "Allow ssh inbound traffic"
  vpc_id      = aws_vpc.peerpod_vpc.id

 ingress {
    description = "ingress rule for icmp access"
    from_port        = -1
    to_port          = -1
    protocol         = "icmp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    }

  ingress {
    description = "ingress rule for ssh access"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    }  

   ingress {
    description = "ingress rule for https traffic"
    from_port        = 6443
    to_port          = 6443
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

  egress {
    description = "egress rule for https traffic"
    from_port        = 6443
    to_port          = 6443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    }  

  tags = {
    Name = "peer-pod-sg"
  }

}


#Create an Ubuntu 20.04 instance
resource "aws_instance" "peer-pods-ec2-master"{
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
    Name = "peer-pods-ec2-k8smaster"
  }
}

resource "aws_instance" "peer-pods-ec2-worker"{
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
    Name = "peer-pods-ec2-k8sworker"
  }
}

resource "aws_instance" "ansible-master"{
  ami = "ami-0fc231e7d7af4036b"
  instance_type = "t2.micro"
  key_name = var.ec2_ssh_key_name
  subnet_id = aws_subnet.peerpod_subnet.id
  availability_zone = "us-west-2b"
  vpc_security_group_ids = [aws_security_group.peerpod_sg.id]
  user_data = <<-EOF
              #!/bin/bash
              wget https://raw.githubusercontent.com/abhbaner/peer-pods-automation/master/ansible_setup.sh -P /home/ubuntu/
              chmod +x /home/ubuntu/ansible_setup.sh
              mkdir /home/ubuntu/ansible-k8s-setup
              wget https://raw.githubusercontent.com/abhbaner/peer-pods-automation/master/ansible-k8s-setup/ansible.cfg -P /home/ubuntu/ansible-k8s-setup/
              wget https://raw.githubusercontent.com/abhbaner/peer-pods-automation/master/ansible-k8s-setup/hosts -P /home/ubuntu/ansible-k8s-setup/
              wget https://raw.githubusercontent.com/abhbaner/peer-pods-automation/master/ansible-k8s-setup/k8s-pkg.yml -P /home/ubuntu/ansible-k8s-setup/
              wget https://raw.githubusercontent.com/abhbaner/peer-pods-automation/master/ansible-k8s-setup/k8s-master.yml -P /home/ubuntu/ansible-k8s-setup/
              wget https://raw.githubusercontent.com/abhbaner/peer-pods-automation/master/ansible-k8s-setup/k8s-workers.yml -P /home/ubuntu/ansible-k8s-setup/
              EOF
  tags = {
    Name = "ansible-master"
  }
}


output "k8smaster_public_ip" {
  value = aws_instance.peer-pods-ec2-master.public_ip
}

output "k8smaster_private_ip" {
  value = aws_instance.peer-pods-ec2-master.private_ip
}

output "ec2_instance_id_k8smaster" {
  value = aws_instance.peer-pods-ec2-master.id
}

output "k8sworker_public_ips" {
  value = aws_instance.peer-pods-ec2-worker.public_ip
}

output "k8sworker_private_ips" {
  value = aws_instance.peer-pods-ec2-worker.private_ip
}

output "ec2_instance_id_k8sworker" {
  value = aws_instance.peer-pods-ec2-worker.id
}

output "ansibleMaster_public_ips" {
  value = aws_instance.ansible-master.public_ip
}

output "ansibleMaster_private_ips" {
  value = aws_instance.ansible-master.private_ip
}

output "ec2_instance_id_ansibleMaster" {
  value = aws_instance.ansible-master.id
}


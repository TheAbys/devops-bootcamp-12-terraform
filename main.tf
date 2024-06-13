provider "aws" {
  region = "eu-central-1"
}

variable vpc_cidr_block {}
variable subnet_cidr_block {}
variable avail_zone {}
variable env_prefix {}
variable my_ip {}
variable instance_type {}
variable public_key_location {}

resource "aws_vpc" "myapp-vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name: "${var.env_prefix}-vpc"
  }
}

resource "aws_subnet" "myapp-subnet-1" {
  vpc_id = aws_vpc.myapp-vpc.id
  cidr_block = var.subnet_cidr_block
  availability_zone = var.avail_zone
  tags = {
    Name: "${var.env_prefix}-subnet-1"
  }
}

resource "aws_internet_gateway" "myapp-igw" {
  vpc_id = aws_vpc.myapp-vpc.id

  tags = {
    Name: "${var.env_prefix}-igw"
  }
}

resource "aws_default_route_table" "main-rtb" {
  default_route_table_id = aws_vpc.myapp-vpc.default_route_table_id

    # we don't have to define the route for the internal communcation
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myapp-igw.id
  }
  tags = {
    Name: "${var.env_prefix}-main-rtb"
  }
}

resource "aws_default_security_group" "default-sg" {
  vpc_id = aws_vpc.myapp-vpc.id

  # we just open one specific port, but we could also open from port 1 to 1000 e.g.
  ingress {
    from_port = 22
    to_port = 22
    protocol = "TCP"
    cidr_blocks = [var.my_ip]
  }

  # 0.0.0.0/0 means any ip address can reach our application
  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # installing tools like docker on the server needs access to the internet for downloading binaries etc.
  # port 0 means every port and protocol -1 means every protocol
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    prefix_list_ids = []
  }

  tags = {
    Name: "${var.env_prefix}-default-sg"
  }
}

# load the most recent version of the amazon linux ami
data "aws_ami" "latest-amazon-linux-image" {
  most_recent = true
  owners = ["amazon"]
  filter {
    name = "name"
    values = ["amzn2-ami-kernel-*-x86_64-gp2"]
  }
  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
}

# output "aws_ami_id" {
#   value       = data.aws_ami.latest-amazon-linux-image.id
# }

output "ec2_public_ip" {
  value = aws_instance.myapp-server.public_ip
}

resource "aws_key_pair" "ssh-key" {
  key_name = "server-key"
  #public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC5ZL6Nhike6kUE/4inopea+CQWXhj7NVIA1rDi6GbOpwks5+4WCPiNZgPQBmFcQTKmewjVNEhkiEfvauv12NVF7mc19iWt/ep1QFsmsCjqRb/aaMqOuE9NlnYC7Iq5sxtVNGaeo/J15lcbsKhk2Mp6VUD/arChY2k10VTcir51ux5avBSYIWmkYJMUTVYMNWRDp2Bhh6rZXjvw7pfnLqWhg7L14SCaF37hRLWXUGz1vy30NyX+nRzLMY2Pk+gK1r7QI6m6EzUO/yYAhIWrLt78YfRWNEX8tu3YclqSrFLuVpam8K38Ow1j6QaaxP747M4k9a4WBQBp1/D9u8XVpNYd8cuh5y7c1f/oWbtrIgV4L4F5scZt4yvLoyAIA+la0GIbj1GcxDX6tyUv2MjuTB0qab6r0fzpoH/+e+33Gn9H5OSAAwDaApp9t/Tf2ghLzJ87P/3AYiVdPDUwAZ2NZNRG5RyG5HFREkKabUMJr0TxFePLeMICikB8KRFbdvFQA1c= mueller@mueller-virtual-machine"
  public_key = file(var.public_key_location)
}

resource "aws_instance" "myapp-server" {
  ami = data.aws_ami.latest-amazon-linux-image.id
  instance_type = var.instance_type

  # optional variables, but not setting them means they are placed in the default vpc etc.
  subnet_id = aws_subnet.myapp-subnet-1.id
  vpc_security_group_ids = [aws_default_security_group.default-sg.id]
  availability_zone = var.avail_zone

  associate_public_ip_address = true
  key_name = aws_key_pair.ssh-key.key_name

  user_data = <<EOF
    #!/bin/bash
    sudo yum update -y && sudo yum install -y docker
    sudo systemctl start docker
    sudo usermod -aG docker ec2-user
    docker run -p 8080:80 nginx
  EOF

  # when the user_data script changes the server is recreated, if anything else is changed it depends on the other changes if a recreation is required, adding a tag e.g. doesn't force recreation
  user_data_replace_on_change = true

  tags = {
    Name: "${var.env_prefix}-server"
  }
}
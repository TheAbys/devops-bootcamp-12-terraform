resource "aws_default_security_group" "default-sg" {
  vpc_id = var.vpc_id

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
    values = [var.image_name]
  }
  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_key_pair" "ssh-key" {
  key_name = "server-key"
  public_key = file(var.public_key_location)
}

resource "aws_instance" "myapp-server" {
  ami = data.aws_ami.latest-amazon-linux-image.id
  instance_type = var.instance_type

  # optional variables, but not setting them means they are placed in the default vpc etc.
  subnet_id = var.subnet_id
  vpc_security_group_ids = [aws_default_security_group.default-sg.id]
  availability_zone = var.avail_zone

  associate_public_ip_address = true
  key_name = aws_key_pair.ssh-key.key_name

  user_data = file("entry-script.sh")

  # when the user_data script changes the server is recreated, if anything else is changed it depends on the other changes if a recreation is required, adding a tag e.g. doesn't force recreation
  user_data_replace_on_change = true

  tags = {
    Name: "${var.env_prefix}-server"
  }
}
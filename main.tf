provider "aws" {
  region = "eu-central-1"
  #access_key = "ASIAW3MEC6X5GMXARVHX"
  #secret_key = "Apq+OHadtxKjxU1wZsVQYdVnJWl3oQNNBoejvcD3"
}

variable "cidr_blocks" {
  description = "subnet cidr block"
  type = list(string)
}

resource "aws_vpc" "development-vpc" {
  cidr_block = var.cidr_blocks[0]
  tags = {
    Name: "Development"
  }
}

resource "aws_subnet" "dev-subnet-1" {
  vpc_id = aws_vpc.development-vpc.id
  cidr_block = var.cidr_blocks[1]
  availability_zone = "eu-central-1a"
  tags = {
    Name: "subnet-1-dev"
  }
}

output "dev-vpc-id" {
  value = aws_vpc.development-vpc.id
}

output "dev-vpcsubnet-id" {
  value = aws_subnet.dev-subnet-1.id
}
provider "aws" {
  region = "eu-north-1"
}

terraform {
  backend "s3" {
  bucket = "bazcorp-bucket1"
  key = "dev/network/terraform.tfstate"
  region = "eu-north-1"
  }
}


variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "env" {
  default = "dev"
}

variable "public_subnet_cidrs" {
  default = [
    "10.0.1.0/24",
    "10.0.2.0/24"
  ]
}


#-----------------------------------------

data "aws_availability_zones" "available" {}


resource "aws_vpc" "main_vpc" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "${var.env}-vpc"
  }
  }

resource "aws_internet_gateway" "main_gate1" {
  vpc_id = aws_vpc.main_vpc.id
  tags = {
    Name = "${var.env}-igw"
  }
}

resource "aws_subnet" "public_subnet" {
  count = length(var.public_subnet_cidrs)
  vpc_id = "vpc-0e7d2ee0c06088a7e"  # aws_vpc.main_vpc.id?
  cidr_block = element(var.public_subnet_cidrs, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.env}-public-${count.index +1}"
  }
}

resource "aws_route_table" "public_subnets_table" {
  vpc_id = aws_vpc.main_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_gate1.id
    }
    tags = {
      Name = "${var.env}-route-public-subnets"
    }
  }


resource "aws_route_table_association" "public_route" {
  count = length(aws_subnet.public_subnet[*].id)
  route_table_id = aws_route_table.public_subnets_table.id
  subnet_id = element(aws_subnet.public_subnet[*].id, count.index)
}


#------------------------------------------------

output "vpc_id" {
  value = aws_vpc.main_vpc.id
}

output "vpc_cidr" {
  value = aws_vpc.main_vpc.cidr_block
}

output "public_subnet_ids" {
  value = aws_subnet.public_subnet[*].id
}

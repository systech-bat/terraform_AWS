provider "aws" {
  region = "eu-north-1"
}

variable "env" {
  default = "prod"
}

variable "prod_owner" {
  default = "BazCorp"
}

variable "dev_owner" {
  default = "BazCorp_dev"
}

variable "ec2_size" {
  default = {
    "prod" = "t3.small"
    "dev" = "t3.micro"
    "staging" = "t3.medium"
  }
}

variable "allow_port_list" {
  default = {
    "prod" = ["80", "443"]
    "dev" = ["80", "443", "22", "8080"]
  }
}


data "aws_ami" "latest_ubuntu" {
  owners = ["099720109477"]
  most_recent = true
  filter {
    name = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

resource "aws_instance" "my_serv1" {
  ami = data.aws_ami.latest_ubuntu.id
#  instance_type = var.env == "prod" ? "t3.small" : "t3.micro"
  instance_type = var.env == "prod" ? var.ec2_size["prod"] : "t3.micro"
  tags = {
  name = "${var.env}-server"
  owner = var.env == "prod" ? var.prod_owner : var.dev_owner
  }
}

resource "aws_instance" "my_serv2" {
  ami = data.aws_ami.latest_ubuntu.id
  instance_type = lookup(var.ec2_size, var.env)
  tags = {
  name = "${var.env}-server"
  owner = var.env == "prod" ? var.prod_owner : var.dev_owner
  }
}


resource "aws_instance" "my_dev_bastion" {
  count = var.env == "dev" ? 1 : 0
  ami = data.aws_ami.latest_ubuntu.id
  instance_type = "t3.micro"
  tags = {
  name = "bastion_dev"
  }
}



resource "aws_security_group" "my_webserver_dyn" {
name        = "Dyn_sec_group"
vpc_id = aws_default_vpc.default.id
dynamic "ingress" {
  for_each = lookup(var.allow_port_list, var.env)
  content{
    from_port        = ingress.value
    to_port          = ingress.value
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}


  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  tags = {
    name = "dyn_security_group1"
    owner = "bazcorp"
  }
}


resource "aws_default_vpc" "default" {
  tags = {
    Name = "Default VPC"
  }
}

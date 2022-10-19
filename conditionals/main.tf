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
  instance_type = var.env == "prod" ? "t3.small" : "t3.micro"
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

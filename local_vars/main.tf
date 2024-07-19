provider "aws" {
  region = "eu-north-1"
}

data  "aws_region" "current" {}
data "aws_availability_zones" "available" {}


locals {
  full_project_name = "${var.Enviroment}-${var.project_name}"
  project_owner = "${var.owner} owner of ${var.project_name}"
  az_list = join(",", data.aws_availability_zones.available.names)
  region = data.aws_region.current.description
  location = "in ${local.region} there are AZ: ${local.az_list}"
}


resource "aws_instance" "my_webs1" {
  count = 2
  ami = "ami-01977e30682e5df74" # amazon linux ami
  instance_type = "t3.micro"
  vpc_security_group_ids = [aws_security_group.my_webserver.id]
}

resource "aws_security_group" "my_webserver" {
  name        = "webserver security group"
  description = "sec_group1"
  vpc_id = aws_default_vpc.default.id
    tags = {
      region_azs = local.az_list
      location = local.location
    }
  }


  resource "aws_default_vpc" "default" {
    tags = {
      Name = "Default VPC"
    }
  }

  resource "aws_eip" "my_static_ip1" {
    instance = aws_instance.my_webs1[1].id
    vpc      = true
    tags = {
      Name = "static IP"
      Owner = "var.owner"
      Project = local.full_project_name
      project_owner = local.project_owner
    }
  }

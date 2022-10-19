provider "aws" {
  region = "eu-north-1"
}

data "aws_ami" "latest_ubuntu" {
  owners = ["099720109477"]
  most_recent = true
  filter {
    name = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

output "ubuntu_latest_ami_id" {
  value = data.aws_ami.latest_ubuntu.id
}

output "ubuntu_latest_ami_name" {
  value = data.aws_ami.latest_ubuntu.name
}

data "aws_ami" "latest_windows" {
  owners = ["amazon"]
  most_recent = true
  filter {
  name = "name"
  values = ["Windows_Server-2019-English-Full-Base-*"]
  }
}

output "windows_latest_ami_name" {
  value = data.aws_ami.latest_windows.name
}

output "windows_latest_ami_id" {
  value = data.aws_ami.latest_windows.id
}

data "aws_ami" "latest_amazon_linux" {
  owners = ["amazon"]
  most_recent = true
  filter {
  name = "name"
  values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

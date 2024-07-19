provider "aws" {
  region = "eu-north-1"
}

provider "aws" {
  region = "eu-central-1"
  alias = "central"
}

provider "aws" {
  region = "eu-west-1"
  alias = "west"
}

#---------------------------------------------------------


data "aws_ami" "latest_ubuntu" {
  owners = ["099720109477"]
  most_recent = true
  filter {
    name = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

data "aws_ami" "latest_ubuntu_central" {
  provider = aws.central
  owners = ["099720109477"]
  most_recent = true
  filter {
    name = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

data "aws_ami" "latest_ubuntu_west" {
  provider = aws.west
  owners = ["099720109477"]
  most_recent = true
  filter {
    name = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

resource "aws_instance" "server1" {
  instance_type = "t3.micro"
  ami = data.aws_ami.latest_ubuntu.id
  tags = {
    name = "server1"
  }
  }

resource "aws_instance" "server2" {
    provider = aws.west
    instance_type = "t3.micro"
    ami = data.aws_ami.latest_ubuntu_west.id
    tags = {
      name = "server1_west"
    }
    }

resource "aws_instance" "server3" {
      provider = aws.central
      instance_type = "t3.micro"
      ami = data.aws_ami.latest_ubuntu_central.id
      tags = {
        name = "server1_central"
      }
      }

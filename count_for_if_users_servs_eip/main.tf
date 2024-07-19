provider "aws" {
  region = "eu-north-1"
}


resource "aws_iam_user" "user1" {
  name = "user07"
  }


variable "aws_users" {
  description = "List of IAM users to create"
  default = ["user01", "user02", "user03", "user04", "user05", "user06", "user"]
}

resource "aws_iam_user" "users" {
  count = length(var.aws_users)
  name = element(var.aws_users, count.index)
}

output "created_iam_users_all" {
  value = aws_iam_user.users
}

output "created_iam_users_id" {
  value = aws_iam_user.users[*].id
}
output "created_iam_users_custom" {
  value = [
  for user in aws_iam_user.users:
  "Hello Username:${user.name} has ARN ${user.arn}"
  ]
}

output "Created_IAM_users_map" {
  value = {
    for user in aws_iam_user.users:
    user.unique_id => user.id
  }
}

# print list of users if name = 4 simbols
output "custom_if_length" {
  value = [
    for x in aws_iam_user.users:
    x.name
    if length(x.name) == 4
  ]
  }

#-----------------------

data "aws_ami" "latest_ubuntu" {
  owners = ["099720109477"]
  most_recent = true
  filter {
    name = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}


resource "aws_instance" "servers" {
  count = 3
  ami = data.aws_ami.latest_ubuntu.id
  instance_type = "t3.micro"
  vpc_security_group_ids = [aws_security_group.my_webserver.id]
  tags = {
  name = "Server ${count.index +1}"
  }

}

resource "aws_eip" "my_static_ip" {
  count = 3
  vpc      = true
  instance = aws_instance.servers[count.index].id
}

resource "aws_default_vpc" "default" {
  tags = {
    Name = "Default VPC"
  }
}

resource "aws_security_group" "my_webserver" {
  name        = "webserver security group"
  description = "sec_group1"
  vpc_id = aws_default_vpc.default.id
  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]

  }

  ingress {
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}

output "server_all" {
  value = {
  for server in aws_instance.servers:
  server.id => server.public_ip
  }
  }

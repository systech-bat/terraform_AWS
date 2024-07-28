provider "aws" {
  region = "us-west-2"
}

resource "aws_instance" "Test_server01" {
  ami                    = "ami-095413544ce52437d"
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.Test_server.id]
  key_name = "oregon_key"
  tags = {
    Name  = "Test_server"
    Owner = "someone"
  }
}

resource "aws_security_group" "Test_server" {
  name        = "Test Security Group"
  description = "My SecurityGroup"

  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]

  }


  tags = {
    Name  = "Test_Server SecurityGroup"
    Owner = "someone"
  }
}

resource "aws_eip" "my_static_ip" {
  instance = aws_instance.Test_server.id
}

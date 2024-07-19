provider "aws" {
  region = "eu-central-1"
}


resource "aws_eip" "my_static_ip" {
  instance = aws_instance.my_webs1.id
}

resource "aws_instance" "my_webserver" {
  ami                    = "ami-03a71cec707bfc3d7"
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.my_webserver.id]
  user_data = templatefile("script.sh.tpl", {
    f_name = "Edward",
    l_name = "Arutyunyan",
    names  = ["name1", "name2", "name3", "name4", "name5"]
  })

  tags = {
    Name  = "Web Server Build by Terraform"
    Owner = "Edward Arutyunyan"
  }
}


resource "aws_security_group" "my_webserver" {
  name        = "WebServer Security Group"
  description = "My First SecurityGroup"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name  = "Web Server SecurityGroup"
    Owner = "Edward Arutyunyan"
  }
}

#web server
#made by me

provider "aws" {
  region = "eu-north-1"
}

resource "aws_eip" "my_static_ip" {
  instance = aws_instance.my_webs1.id
}

resource "aws_eip" "my_static_ip2" {
  instance = aws_instance.my_webs2.id
}

resource "aws_eip" "my_static_ip3" {
  instance = aws_instance.my_webs3.id
}

resource "aws_eip" "my_static_ip4" {
  instance = aws_instance.my_webs4.id
}

resource "aws_instance" "my_webs1" {
  ami = "ami-01977e30682e5df74" # amazon linux ami
  instance_type = "t3.micro"
  vpc_security_group_ids = [aws_security_group.my_webserver.id]
  user_data = file("script.sh")

tags = {
  Name = "web_server1_by_baz"
  owner = "bazcorp"
}
  depends_on = [aws_instance.my_webs3]
}

resource "aws_instance" "my_webs2" {
  ami = "ami-01977e30682e5df74" # amazon linux ami
  instance_type = "t3.micro"
  vpc_security_group_ids = [aws_security_group.my_webserver.id]
  user_data = file("script.sh")

tags = {
  Name = "web_server2_by_baz"
    owner = "bazcorp"
}
depends_on = [aws_instance.my_webs1]
}


resource "aws_instance" "my_webs3" {
  ami = "ami-01977e30682e5df74" # amazon linux ami
  instance_type = "t3.micro"
  vpc_security_group_ids = [aws_security_group.my_webserver.id]
  user_data = file("script.sh")

tags = {
  Name = "web_server3_by_baz"
  owner = "bazcorp"
}
}

resource "aws_instance" "my_webs4" {
  ami = "ami-01977e30682e5df74" # amazon linux ami
  instance_type = "t3.micro"
  vpc_security_group_ids = [aws_security_group.my_webserver.id]
  user_data = file("script.sh")

tags = {
  Name = "web_server4_by_baz"
  owner = "bazcorp"
}
  depends_on = [aws_instance.my_webs1, aws_instance.my_webs2, aws_instance.my_webs3]
}




resource "aws_security_group" "my_webserver" {
  name        = "webserver security group"
  description = "sec_group1"

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
  tags = {
    name = "web_server1_security_group1"
    owner = "bazcorp"
  }
}

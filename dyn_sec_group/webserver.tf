#web server
#made by me

provider "aws" {
  region = "eu-north-1"
}



resource "aws_security_group" "my_webserver_dyn" {
name        = "Dyn_sec_group"
dynamic "ingress" {
  for_each = ["80", "8080", "443", "3389", "9000", "1541", "9092", "1543"]
  content{
    from_port        = ingress.value
    to_port          = ingress.value
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}

#extra ssh rule for private ip
  ingress {
  from_port = 22
  to_port = 22
  protocol = "tcp"
  cidr_blocks = ["10.10.0.0/16"]
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

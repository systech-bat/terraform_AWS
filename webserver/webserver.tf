#web server
#made by Baz

provider "aws" {
  region = "eu-north-1"
}

resource "aws_eip" "my_static_ip" {
  instance = aws_instance.my_webs1.id
  vpc      = true
}

resource "aws_instance" "my_webs1" {
  ami = "ami-01977e30682e5df74" # amazon linux ami
  instance_type = "t3.micro"
  vpc_security_group_ids = [aws_security_group.my_webserver.id]
  user_data = <<EOF
#!/bin/bash
yum -y update
yum -y install httpd
myip=`curl http://169.254.169.254/latest/meta-data/local-ipv4`
#echo "<h2>WebServer with IP: $myip</h2><br>каждый знает каждый гражданин кто хуйло #1'"  >  /var/www/html/index.html
echo "<h2>WebServer with IP: каждый знает каждый гражданин кто хуйло #1'"  >  /var/www/html/index.html
#echo "<br><front color="blue">hello world - this is a test web server" >> /var/www/html/index.html
sudo service httpd start
chkconfig httpd on
EOF

tags = {
  name = "web_server1_by_baz"
  owner = "bazcorp"
}
  lifecycle {
    ignore_changes = [ami,user_data]
    prevent_destroy = false
    create_before_destroy = true
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
  tags = {
    name = "web_server1_security_group1"
    owner = "bazcorp"
  }
}

resource "aws_default_vpc" "default" {
  tags = {
    Name = "Default VPC"
  }
}


output "webserver_instance_id" {
  value = aws_instance.my_webs1.id
}

output "webserver_public_ip" {
  value = aws_eip.my_static_ip.public_ip
}

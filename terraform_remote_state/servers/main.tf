provider "aws" {
  region = "eu-north-1"
}

terraform {
  backend "s3" {
  bucket = "bazcorp-bucket1"
  key = "dev/security_groups/terraform.tfstate"
  region = "eu-north-1"
  }
}


#--------------------------------------------------------------

data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "bazcorp-bucket1"
    key = "dev/network/terraform.tfstate"
    region = "eu-north-1"
  }
}


data "aws_ami" "latest_amazon_linux" {
  owners = ["amazon"]
  most_recent = true
  filter {
  name = "name"
  values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}


#----------------------------------------------------------------


resource "aws_instance" "web_server1" {
  ami = data.aws_ami.latest_amazon_linux.id
  instance_type = "t3.micro"
  vpc_security_group_ids = [aws_security_group.my_webserver.id]
  subnet_id = data.terraform_remote_state.network.outputs.public_subnet_ids[0]
  user_data = <<EOF
  #!/bin/bash
  yum -y update
  yum -y install httpd
  myip=`curl http://169.254.169.254/latest/meta-data/local-ipv4`
  echo "<h2>WebServer with IP: $myip</h2><br>Build by remote state!"  >  /var/www/html/index.html
  echo "<br><front color="blue">test text" >> /var/www/html/index.html
  sudo service httpd start
  chkconfig httpd on
  EOF
  tags = {
    Name = "Web Server"
  }
}



resource "aws_security_group" "my_webserver" {
  name        = "webserver security group"
  description = "sec_group1"
  vpc_id = data.terraform_remote_state.network.outputs.vpc_id
  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
}

    ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = [data.terraform_remote_state.network.outputs.vpc_cidr]

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




output "network_details"{
  value = data.terraform_remote_state.network
}

output "web_server_sec_group_id"{
  value = aws_security_group.my_webserver.id
}

output "web_server_public_ip"{
  value = aws_instance.web_server1.public_ip
}

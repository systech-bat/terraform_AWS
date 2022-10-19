#web server
#made by Baz



provider "aws" {
  region = var.region
}

resource "aws_eip" "my_static_ip" {
  instance = aws_instance.my_webs1.id
  tags = merge(var.common_tags, {name = "${var.common_tags["Enviroment"]}Server IP"})
}

data "aws_ami" "latest_amazon_linux" {
  owners = ["amazon"]
  most_recent = true
  filter {
  name = "name"
  values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_instance" "my_webs1" {
  ami = data.aws_ami.latest_amazon_linux.id # amazon linux ami
  instance_type = var.instance_type
  vpc_security_group_ids = [aws_security_group.my_webserver_dyn.id]
  user_data = file("script.sh")
  monitoring = var.enable_detailed_monitoring


tags = merge(var.common_tags, {name = "web_server1"})

  lifecycle {

    create_before_destroy = true
  }
}


resource "aws_security_group" "my_webserver_dyn" {
name        = "Dyn_sec_group"
dynamic "ingress" {
  for_each = var.allow_ports
  content{
    from_port        = ingress.value
    to_port          = ingress.value
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}


egress {
  from_port        = 0
  to_port          = 0
  protocol         = "-1"
  cidr_blocks      = ["0.0.0.0/0"]
}

tags = merge(var.common_tags, { name = "dyn_security_group1"})

}

output "webserver_instance_id" {
  value = aws_instance.my_webs1.id
}

output "webserver_public_ip" {
  value = aws_eip.my_static_ip.public_ip
}

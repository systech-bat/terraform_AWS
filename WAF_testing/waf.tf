provider "aws" {
  region = "eu-central-1"
}

# creating extra volumes
resource "aws_ebs_volume" "volume01" {
  count = length(aws_instance.web_servers)
  availability_zone = element(
    ["eu-central-1a", "eu-central-1b", "eu-central-1c"],
    count.index
  )
  size  = 11
  type  = "gp3"
  tags = {
    Name = "sdf_0${count.index + 1}"
  }
}

# vpc choose
variable "existing_vpc_id" {
  description = "choose vpc"
  type        = string
  default     = "vpc-008dfc71ba936018e"
}

# SG
resource "aws_security_group" "waf_sg" {
  name        = "webserver security group"
  description = "sec_group1"

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

  ingress {
    from_port   = 22
    to_port     = 22
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
    name  = "waf_test_sg"
    owner = "bazcorp"
  }
}

# instances
resource "aws_instance" "web_servers" {
  count                 = 3
  ami                   = "ami-0faab6bdbac9486fb"
  vpc_security_group_ids = [aws_security_group.waf_sg.id]
  instance_type         = "t3.micro"
  key_name              = "eu_central_key"
  subnet_id = element(["subnet-03926859c7958fd90", "subnet-0cf189dac65d8c8b5", "subnet-021fc2ebc23791190"], count.index)

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 10
    delete_on_termination = true

    tags = {
      Name = "Server_root_volume 0${count.index + 1}"
    }
  }

  user_data = <<EOF
#!/bin/bash
apt -y update
apt -y install nginx
echo "web_server#${count.index + 1}" > /var/www/html/index.nginx-debian.html
sudo systemctl restart nginx
EOF

  tags = {
    Name     = "Server_app 0${count.index + 1}"
    Backup01 = "true"
  }
}

# volumes mounting
resource "aws_volume_attachment" "ebs_att" {
  count       = length(aws_instance.web_servers)
  device_name = "/dev/sdf"
  instance_id = aws_instance.web_servers[count.index].id
  volume_id   = aws_ebs_volume.volume01[count.index].id
}

# TG
resource "aws_lb_target_group" "mywaftg01" {
  name        = "MyWAFTG01"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.existing_vpc_id
  target_type = "instance"

  health_check {
    interval            = 6
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 2
    matcher             = "200"
  }

  tags = {
    Name = "WAFTG01"
  }
}


resource "aws_lb_target_group_attachment" "tg_attachment" {
  count            = length(aws_instance.web_servers)
  target_group_arn = aws_lb_target_group.mywaftg01.arn
  target_id        = aws_instance.web_servers[count.index].id
  port             = 80
}

# ALB
resource "aws_lb" "WAF-ALB01" {
  name               = "WAF-ALB01"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.waf_sg.id]
  subnets            = ["subnet-03926859c7958fd90", "subnet-0cf189dac65d8c8b5", "subnet-021fc2ebc23791190"]

  enable_deletion_protection = false

  tags = {
    Name = "WAF_ALB"
  }
}

# Listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.WAF-ALB01.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.mywaftg01.arn
  }
}

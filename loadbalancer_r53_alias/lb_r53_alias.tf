provider "aws" {
  region = "eu-central-1"
}

#ec2---------------------------------------------------------
resource "aws_ebs_volume" "volume01" {
  count = length(aws_instance.lb_servers)
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


variable "existing_vpc_id" {
  description = "choose vpc"
  type        = string
  default     = "vpc-008dfc71ba936018e"
}


resource "aws_instance" "lb_servers" {
  count                 = 3
  ami                   = "ami-0faab6bdbac9486fb"
  vpc_security_group_ids  = ["sg-058a6319422a1c348"]
  instance_type         = "t2.micro"
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
echo "load_balacer_server#${count.index + 1}" > /var/www/html/index.nginx-debian.html
sudo systemctl restart nginx
EOF

  tags = {
    Name     = "Server_app 0${count.index + 1}"
    Backup01 = "true"
  }
}


resource "aws_volume_attachment" "ebs_att" {
  count       = length(aws_instance.lb_servers)
  device_name = "/dev/sdf"
  instance_id = aws_instance.lb_servers[count.index].id
  volume_id   = aws_ebs_volume.volume01[count.index].id
}

#TG-----------------------------------------------------------------

resource "aws_lb_target_group" "lb_alias" {
  name        = "LB-TG01"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.existing_vpc_id
  target_type = "instance"

  health_check {
    interval            = 6
    path                = "/index.nginx-debian.html"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 2
    matcher             = "200"
  }

  tags = {
    Name = "lb_alias01"
  }
}


resource "aws_lb_target_group_attachment" "tg_attachment" {
  count            = length(aws_instance.lb_servers)
  target_group_arn = aws_lb_target_group.lb_alias.arn
  target_id        = aws_instance.lb_servers[count.index].id
  port             = 80
}

#lb---------------------------------------------------
resource "aws_lb" "lb_alias" {
  name               = "lb-alias"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["sg-058a6319422a1c348"]
  subnets            = ["subnet-03926859c7958fd90", "subnet-0cf189dac65d8c8b5", "subnet-021fc2ebc23791190"]

  enable_deletion_protection = false

  tags = {
    Name = "WAF_ALB"
  }
}


resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.lb_alias.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb_alias.arn
  }
}

#r53_alias---------------------------------------------------------------------

resource "aws_route53_record" "lb_alias" {
  zone_id = "Z0549877YRZJ4EC9VA0L"
  name    = "lb"
  type    = "A"

  alias {
    name                   = aws_lb.lb_alias.dns_name
    zone_id                = aws_lb.lb_alias.zone_id
    evaluate_target_health = true
}
}

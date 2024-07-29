provider "aws" {
  region = "eu-central-1"
}

# Creating extra volumes
resource "aws_ebs_volume" "volume01" {
  availability_zone = "eu-central-1c"
  count             = length(aws_instance.event_servers)
  size              = 11
  type              = "gp3"
  tags = {
    Name = "event_0${count.index + 1}"
  }
}

# VPC choose
variable "existing_vpc_id" {
  description = "choose vpc"
  type        = string
  default     = "vpc-008dfc71ba936018e"
}

# Server
resource "aws_instance" "event_servers" {
  availability_zone      = "eu-central-1c"
  count                  = 1
  ami                    = "ami-0faab6bdbac9486fb"
  vpc_security_group_ids = ["sg-058a6319422a1c348"]
  instance_type          = "t3.micro"
  key_name               = "eu_central_key"
  subnet_id              = "subnet-021fc2ebc23791190"
  root_block_device {
    volume_type           = "gp3"
    volume_size           = 10
    delete_on_termination = true
    tags = {
      Name = "Server_root_volume 0${count.index + 1}"
    }
  }

  # User data
  user_data = <<EOF
#!/bin/bash
apt -y update
apt -y install nginx
echo "event #${count.index + 1}" > /var/www/html/index.nginx-debian.html
sudo systemctl restart nginx
EOF

  tags = {
    Name      = "Event_bridge 0${count.index + 1}"
    Backup01  = "true"
  }
}

# Volumes mounting
resource "aws_volume_attachment" "ebs_att" {
  count       = length(aws_instance.event_servers)
  device_name = "/dev/sdf"
  instance_id = aws_instance.event_servers[count.index].id
  volume_id   = aws_ebs_volume.volume01[count.index].id
}

# Topic
resource "aws_sns_topic" "event_bridge" {
  name         = "event_bridge"
  display_name = "event_bridge"
}

# SNS Sub
resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.event_bridge.arn
  protocol  = "email"
  endpoint  = "BazArutyunyan@gmail.com"
}

# Rule
resource "aws_cloudwatch_event_rule" "ec2_state" {
  name        = "ec2_state"
  event_bus_name = "default"
  description = "ec2 changing state notification"
  event_pattern = templatefile("${path.module}/event_pattern.json.tpl", {})
}

# Target
resource "aws_cloudwatch_event_target" "send_to_sns" {
  rule      = aws_cloudwatch_event_rule.ec2_state.name
  target_id = "send-to-sns"
  arn       = aws_sns_topic.event_bridge.arn
}

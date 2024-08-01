provider "aws" {
  region = "eu-central-1"
}

# Creating extra volumes
resource "aws_ebs_volume" "volume01" {
  availability_zone = "eu-central-1c"
  count             = length(aws_instance.CW_alarm)
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
resource "aws_instance" "CW_alarm" {
  availability_zone      = "eu-central-1c"
  count                  = 1
  ami                    = "ami-0faab6bdbac9486fb"
  vpc_security_group_ids = ["sg-058a6319422a1c348"]
  instance_type          = "t2.micro"
  key_name               = "eu_central_key"
  monitoring             = true
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
echo "CW_alarm #${count.index + 1}" > /var/www/html/index.nginx-debian.html
sudo systemctl restart nginx
EOF

  tags = {
    Name      = "CW_alarm0${count.index + 1}"
    Backup01  = "true"
  }
}

# Volumes mounting
resource "aws_volume_attachment" "ebs_att" {
  count       = length(aws_instance.CW_alarm)
  device_name = "/dev/sdf"
  instance_id = aws_instance.CW_alarm[count.index].id
  volume_id   = aws_ebs_volume.volume01[count.index].id
}

# Topic
resource "aws_sns_topic" "CW_alarm" {
  name         = "CW_alarm"
  display_name = "CW_alarm"
}

# SNS Sub
resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.CW_alarm.arn
  protocol  = "email"
  endpoint  = "BazArutyunyan@gmail.com"
}


# CW alarm
resource "aws_cloudwatch_metric_alarm" "cpu_utilization_alarm" {
  alarm_name          = "CPU > 75%"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60 # 1 minute intervals
  statistic           = "Average"
  threshold           = 75
  alarm_description   = "CPU > 75%."
  alarm_actions       = [aws_sns_topic.CW_alarm.arn]
  dimensions = {
    InstanceId = aws_instance.CW_alarm[0].id
  }
  treat_missing_data = "notBreaching"
}

provider "aws" {
  region = "eu-central-1"
}

# Creating extra volumes
resource "aws_ebs_volume" "volume01" {
  availability_zone = "eu-central-1c"
  count             = length(aws_instance.CW_agent)
  size              = 11
  type              = "gp3"
  tags = {
    Name = "sdf_0${count.index +1}"
  }
}

# VPC choose
variable "existing_vpc_id" {
  description = "choose vpc"
  type        = string
  default     = "vpc-008dfc71ba936018e"
}

# Read the CloudWatch Agent configuration from a local file
data "local_file" "cloudwatch_agent_config" {
  filename = "${path.module}/CWA_config.json"
}

# Server instance
resource "aws_instance" "CW_agent" {
  availability_zone      = "eu-central-1c"
  count                  = 1
  ami                    = "ami-0faab6bdbac9486fb"
  vpc_security_group_ids = ["sg-058a6319422a1c348"]
  instance_type          = "t3.micro"
  key_name               = "eu_central_key"
  subnet_id              = "subnet-021fc2ebc23791190"
  iam_instance_profile   = aws_iam_instance_profile.ec2CWA_instance_profile.name

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 10
    delete_on_termination = true
    tags = {
      Name = "Server_root_volume 0${count.index +1}"
    }
  }

  user_data = <<EOF
#!/bin/bash
apt -y update
apt -y install nginx
apt -y install rsyslog
systemctl start rsyslog
systemctl enable rsyslog
echo "CWA_agent #${count.index +1}'" > /var/www/html/index.nginx-debian.html
sudo systemctl restart nginx
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
dpkg -i -E ./amazon-cloudwatch-agent.deb
cat <<EOT >> /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
${data.local_file.cloudwatch_agent_config.content}
EOT

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s
EOF

  tags = {
    Name     = "Server_app 0${count.index +1}"
    Backup01 = "true"
  }
}

# Volumes mounting
resource "aws_volume_attachment" "ebs_att" {
  count       = length(aws_instance.CW_agent)
  device_name = "/dev/sdf"
  instance_id = aws_instance.CW_agent[count.index].id
  volume_id   = aws_ebs_volume.volume01[count.index].id
}

# IAM Role
resource "aws_iam_role" "ec2CWA" {
  name = "ec2CWA"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Policy attachment
resource "aws_iam_role_policy_attachment" "attach_cloudwatch_policy" {
  role       = aws_iam_role.ec2CWA.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Instance profile
resource "aws_iam_instance_profile" "ec2CWA_instance_profile" {
  name = "ec2CWA_instance_profile"
  role = aws_iam_role.ec2CWA.name
}

provider "aws" {
  region = "eu-central-1"
}

variable "existing_vpc_id" {
  description = "choose vpc"
  type        = string
  default     = "vpc-008dfc71ba936018e"
}

resource "aws_iam_instance_profile" "ssm_prof01" {
  name = "ec2_ssm_instance_profile"
  role = "ec2_ssm"
}


resource "aws_instance" "web_servers" {
  count = 3
  ami                    = "ami-0faab6bdbac9486fb"
  instance_type          = "t3.micro"
  key_name               = "eu_central_key"
  vpc_security_group_ids = ["sg-058a6319422a1c348"]
  iam_instance_profile   = aws_iam_instance_profile.ssm_prof01.name
  user_data = <<EOF
#!/bin/bash
apt -y update
apt -y install nginx
echo "Inspector server #${count.index +1}'"  >  /var/www/html/index.nginx-debian.html
sudo systemctl restart nginx
EOF

  tags = {
    Name    = "Inspector server 0${count.index +1}"
    Backup01 = "true"
  }

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 10
    delete_on_termination = true
    tags = {
      Name = "Server_root_volume 0${count.index +1}"
    }
  }

  subnet_id           = element(["subnet-097a1f4ba1ed54fc3", "subnet-0cf189dac65d8c8b5", "subnet-021fc2ebc23791190"], count.index)
  availability_zone   = element(["eu-central-1a", "eu-central-1b", "eu-central-1c"], count.index)
}

resource "aws_ebs_volume" "volume01" {
  count            = 3
  availability_zone = element(["eu-central-1a", "eu-central-1b", "eu-central-1c"], count.index)
  size             = 11
  type             = "gp3"
  tags = {
    Name = "sdf_0${count.index +1}"
  }
}

resource "aws_volume_attachment" "ebs_att" {
  count       = 3
  device_name = "/dev/sdf"
  instance_id = aws_instance.web_servers[count.index].id
  volume_id   = aws_ebs_volume.volume01[count.index].id
}

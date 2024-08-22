provider "aws" {
  region = "eu-central-1"
}

# ec2---------------------------------------
resource "aws_ebs_volume" "volume01" {
  availability_zone = "eu-central-1c"
  count             = length(aws_instance.r53_geolocation)
  size              = 11
  type              = "gp3"
  tags = {
    Name = "sdf_0${count.index + 1}"
  }
}

variable "existing_vpc_id" {
  description = "choose vpc"
  type        = string
  default     = "vpc-008dfc71ba936018e"
}

resource "aws_instance" "r53_geolocation" {
  availability_zone       = "eu-central-1c"
  count                   = 2
  ami                     = "ami-0faab6bdbac9486fb"
  vpc_security_group_ids  = ["sg-058a6319422a1c348"]
  instance_type           = "t2.micro"
  key_name                = "eu_central_key"
  subnet_id               = "subnet-021fc2ebc23791190"
  
  root_block_device {
    volume_type           = "gp3"
    volume_size           = 10
    delete_on_termination = true
    tags = {
      Name = "Server_root_volume 0${count.index + 1}"
    }
  }

  user_data = <<-EOF
    #!/bin/bash
    apt -y update
    apt -y install nginx
    echo "r53_geolocation #${count.index + 1}" > /var/www/html/index.nginx-debian.html
    sudo systemctl restart nginx
  EOF

  tags = {
    Name = "r53_geolocation 0${count.index + 1}"
  }
}

resource "aws_volume_attachment" "ebs_att" {
  count       = length(aws_instance.r53_geolocation)
  device_name = "/dev/sdf"
  instance_id = aws_instance.r53_geolocation[count.index].id
  volume_id   = aws_ebs_volume.volume01[count.index].id
}


#r53-geolocation
resource "aws_route53_record" "geolocation_record" {
  count = length(aws_instance.r53_geolocation)

  zone_id = "Z0549877YRZJ4EC9VA0L"
  name    = "geolocation.bazcorp.link"
  type    = "A"
  ttl     = 60
  records = [aws_instance.r53_geolocation[count.index].public_ip]

  set_identifier = "geolocation_record_${count.index + 1}"

  geolocation_routing_policy {
    country     = count.index == 0 ? "GE" : "DE"
  }
}
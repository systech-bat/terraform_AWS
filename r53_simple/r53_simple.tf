provider "aws" {
  region = "eu-central-1"
}


#ec2-------------------------------------------------

resource "aws_ebs_volume" "volume01" {
  availability_zone = "eu-central-1c"
  count = length(aws_instance.r53_simple)
  size             = 11
  type             = "gp3"
  tags = {
    Name = "sdf_0${count.index +1}"
   }

}

variable "existing_vpc_id" {
  description = "choose vpc"
  type        = string
  default     = "vpc-008dfc71ba936018e"
}

resource "aws_instance" "r53_simple" {
 availability_zone = "eu-central-1c"
 count = 1
 ami = "ami-0faab6bdbac9486fb"
 vpc_security_group_ids = ["sg-058a6319422a1c348"]
 instance_type = "t2.micro"
 key_name = "eu_central_key"
 subnet_id              = "subnet-021fc2ebc23791190"
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
echo "r53_simple #${count.index +1}'"  >  /var/www/html/index.nginx-debian.html
sudo systemctl restart nginx
EOF

tags = {
  Name = "r53_simple 0${count.index +1}"
 }

}

resource "aws_volume_attachment" "ebs_att" {
  count       = length(aws_instance.r53_simple)
  device_name = "/dev/sdf"
  instance_id = aws_instance.r53_simple[count.index].id
  volume_id   = aws_ebs_volume.volume01[count.index].id
}



#R53--------------------------------------------------
resource "aws_route53_record" "r53_simple" {
  zone_id = "Z0549877YRZJ4EC9VA0L"
  name    = "r53-simple.bazcorp.link"
  type    = "A"

  ttl     = 300
  records = [aws_instance.r53_simple[0].public_ip]

  
}
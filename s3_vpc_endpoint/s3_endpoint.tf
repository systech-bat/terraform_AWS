provider "aws" {
  region = "eu-central-1"
}

#IAM------------------------------------------------------------ 
resource "aws_iam_role" "ec2s3role" {
  name = "ec2s3role_for_vpc_endpoint"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ec2s3policy" {
  role       = aws_iam_role.ec2s3role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_instance_profile" "ec2_s3_instance_profile" {
  name = "ec2s3role_for_vpc_endpoint_profile"
  role = aws_iam_role.ec2s3role.name
}

#ec2--------------------------------------------------------------------
resource "aws_ebs_volume" "volume01" {
  availability_zone = "eu-central-1c"
  count = length(aws_instance.s3_server)
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

resource "aws_instance" "s3_server" {
 availability_zone = "eu-central-1c"
 count = 1
 ami = "ami-0faab6bdbac9486fb"
 vpc_security_group_ids = ["sg-058a6319422a1c348"]
 instance_type = "t2.micro"
 key_name = "eu_central_key"
 subnet_id              = "subnet-021fc2ebc23791190"
 iam_instance_profile   = aws_iam_instance_profile.ec2_s3_instance_profile.name
 root_block_device {
    volume_type           = "gp3"
    volume_size           = 10
    delete_on_termination = true
 tags = {
      Name = "S3 server0${count.index +1}"
           }
  }


 user_data = <<EOF
#!/bin/bash
apt -y update
apt -y install nginx
echo "S3 vpc endpoint#${count.index +1}'"  >  /var/www/html/index.nginx-debian.html
sudo systemctl restart nginx
EOF

tags = {
  Name = "S3 server0${count.index +1}"
  Backup = "daily"
 }

}

resource "aws_volume_attachment" "ebs_att" {
  count       = length(aws_instance.s3_server)
  device_name = "/dev/sdf"
  instance_id = aws_instance.s3_server[count.index].id
  volume_id   = aws_ebs_volume.volume01[count.index].id
}


#VPC endpoint-----------------------------------------------

resource "aws_vpc_endpoint" "s3_endpoint" {
  vpc_id             = "vpc-008dfc71ba936018e"
  service_name       = "com.amazonaws.eu-central-1.s3"
  vpc_endpoint_type  = "Gateway"
  route_table_ids    = ["rtb-0a633e98b2985e9a5"]

  tags = {
    Name = "s3-endpoint"
  }

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": "*"
    }
  ]
}
EOF
}

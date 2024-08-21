provider "aws" {
  region = "eu-central-1"
}


#ec2-------------------------------------------------

resource "aws_ebs_volume" "volume01" {
  availability_zone = "eu-central-1c"
  count = length(aws_instance.flow_logs_serv)
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

resource "aws_instance" "flow_logs_serv" {
 availability_zone = "eu-central-1c"
 count = 1
 ami = "ami-0faab6bdbac9486fb"
 vpc_security_group_ids = ["sg-058a6319422a1c348"]
 instance_type = "t3.micro"
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
echo "flow_logs_serv #${count.index +1}'"  >  /var/www/html/index.nginx-debian.html
sudo systemctl restart nginx
EOF

tags = {
  Name = "flow_logs_serv 0${count.index +1}"
 }

}

resource "aws_volume_attachment" "ebs_att" {
  count       = length(aws_instance.flow_logs_serv)
  device_name = "/dev/sdf"
  instance_id = aws_instance.flow_logs_serv[count.index].id
  volume_id   = aws_ebs_volume.volume01[count.index].id
}


#S3-------------------------------------------

resource "aws_s3_bucket" "bazcorp_s3_flow_logs" {
  bucket = "bazcorp-s3-flow-logs"

  versioning {
    enabled = false
  }

  lifecycle_rule {
    id      = "log"
    enabled = true
    prefix  = "log/"
    transition {
      days          = 80
      storage_class = "DEEP_ARCHIVE"
    }
    expiration {
      days = 500
    }
  }

 server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = {
    Name        = "bazcorp-s3-flow-logs"
    Environment = "Dev"
  }
}


#Flow logs---------------------------------------

resource "aws_flow_log" "vpc_flow_log" {
  log_destination_type     = "s3"
  log_destination          = aws_s3_bucket.bazcorp_s3_flow_logs.arn

  traffic_type             = "ALL"
  vpc_id                   = var.existing_vpc_id

  max_aggregation_interval = 60

  destination_options {
    file_format             = "plain-text"
    hive_compatible_partitions = true
    #per_hour_partition      = false    
  }

  tags = {
    Name = "flow-log01"
  }
}
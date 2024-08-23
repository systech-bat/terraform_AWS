provider "aws" {
  region = "eu-central-1"
}


#ec2-------------------------------------------------

resource "aws_ebs_volume" "volume01" {
  availability_zone = "eu-central-1c"
  count = length(aws_instance.r53_fa)
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

resource "aws_instance" "r53_fa" {
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
echo "r53_fa #${count.index +1}'"  >  /var/www/html/index.nginx-debian.html
sudo systemctl restart nginx
EOF

tags = {
  Name = "r53_fa 0${count.index +1}"
 }

}

resource "aws_volume_attachment" "ebs_att" {
  count       = length(aws_instance.r53_fa)
  device_name = "/dev/sdf"
  instance_id = aws_instance.r53_fa[count.index].id
  volume_id   = aws_ebs_volume.volume01[count.index].id
}


#s3----------------------------------------------

resource "aws_s3_bucket" "bazcorp_s3_fa" {
  bucket = "bazcorp.link"

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

 website {
    index_document = "index.html"
    error_document = "error.html"
  }

  tags = {
    Name        = "bazcorp.link"
    Environment = "Dev"
  }
}



resource "aws_s3_bucket_public_access_block" "bazcorp_s3_web_fa" {
  bucket = aws_s3_bucket.bazcorp_s3_fa.id

  block_public_acls       = false
  ignore_public_acls      = false
  block_public_policy     = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "public_policy" {
  bucket = aws_s3_bucket.bazcorp_s3_fa.id

  policy = <<-EOF
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Sid": "SourceIP",
          "Effect": "Deny",
          "Action": "s3:*",
          "Resource": [
            "arn:aws:s3:::bazcorp.link",
            "arn:aws:s3:::bazcorp.link/*"
          ],
          "Condition": {
            "NotIpAddress": {
              "aws:SourceIp": [
                "5.152.58.63"
              ]
            }
          },
          "Principal": "*"
        },
        {
          "Sid": "PublicReadGetObject",
          "Effect": "Allow",
          "Principal": "*",
          "Action": [
        "s3:GetObject",
        "s3:GetObjectVersion"
        ],
          "Resource": "arn:aws:s3:::bazcorp.link/*"
        }
      ]
    }
    EOF
}

resource "aws_s3_object" "index_html" {
  bucket = aws_s3_bucket.bazcorp_s3_fa.bucket
  key    = "index.html"
  source = "${path.module}/index.html"
  etag   = filemd5("${path.module}/index.html")
  content_type = "text/html"
}


# health
resource "aws_route53_health_check" "fa-health" {
  count           = length(aws_instance.r53_fa)
  type            = "HTTP"
  resource_path   = "/index.nginx-debian.html"
  fqdn            = ""
  ip_address      = aws_instance.r53_fa[count.index].public_ip
  port            = 80
  request_interval = 10  
  failure_threshold = 5

  tags = {
    Name = "failover0${count.index + 1}-HC"
  }
}

#r53-fa-----------------------------------------------

resource "aws_route53_record" "record_to_instance" {
  zone_id = "Z0549877YRZJ4EC9VA0L"
  name    = ""             
  type    = "A"
  ttl     = 30
  records = [aws_instance.r53_fa[0].public_ip]

  set_identifier = "1"    
  failover_routing_policy {
    type = "PRIMARY"
  }

  health_check_id = aws_route53_health_check.fa-health[0].id
}

resource "aws_route53_record" "record_to_s3" {
  zone_id = "Z0549877YRZJ4EC9VA0L"
  name    = ""           
  type    = "A"

  alias {
    name                   = "s3-website.eu-central-1.amazonaws.com."
    zone_id                = "Z21DNDUVLTQW6Q"
    evaluate_target_health = false
  }

  set_identifier = "2" 
  failover_routing_policy {
    type = "SECONDARY"
  }
}


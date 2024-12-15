provider "aws" {
  region = "ap-south-1"
}

resource "aws_s3_bucket" "bazcorp_s3" {
  bucket = "bazcorp-cf-oac-01"

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
    Name        = "bazcorp-cf-oac-01"
    Environment = "Dev"
  }
}


resource "aws_s3_bucket_public_access_block" "bazcorp_s3_pub" {
  bucket = aws_s3_bucket.bazcorp_s3.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "public_policy" {
  bucket = aws_s3_bucket.bazcorp_s3.id

  policy = <<-EOF
    {
    "Version": "2012-10-17",
    "Statement": {
        "Sid": "AllowCloudFrontServicePrincipalReadOnly",
        "Effect": "Allow",
        "Principal": {
            "Service": "cloudfront.amazonaws.com"
        },
        "Action": "s3:GetObject",
        "Resource": "arn:aws:s3:::bazcorp-cf-oac-01/*",
        "Condition": {
            "StringEquals": {
                "AWS:SourceArn": "${aws_cloudfront_distribution.bazcorp_cdn01.arn}"
            }
        }
    }
}
    EOF
}

resource "aws_s3_object" "image01" {
  bucket = aws_s3_bucket.bazcorp_s3.bucket
  key    = "6mb.jpg"
  source = "${path.module}/6mb.jpg"
}

resource "aws_s3_object" "image02" {
  bucket = aws_s3_bucket.bazcorp_s3.bucket
  key    = "15mb.jpg"
  source = "${path.module}/15mb.jpg"

}

#oac-------------------------------------------------------------------

resource "aws_cloudfront_origin_access_control" "oac01" {
  name                                 = "oac01"
  description                          = "oac for s3"
  origin_access_control_origin_type    = "s3"
  signing_behavior                     = "no-override"
  signing_protocol                     = "sigv4"
}

#cdn--------------------------------------------------------------------------

resource "aws_cloudfront_distribution" "bazcorp_cdn01" {
  origin {
    domain_name = "${aws_s3_bucket.bazcorp_s3.bucket}.s3.ap-south-1.amazonaws.com"
    origin_id   = "S3-bazcorp-cf-oac-01"
    origin_access_control_id = aws_cloudfront_origin_access_control.oac01.id
  }

  default_cache_behavior {
    target_origin_id       = "S3-bazcorp-cf-oac-01"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]

    compress = true

    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"
  }

  price_class     = "PriceClass_All"
  enabled         = true
  is_ipv6_enabled = true
  comment         = "CF bazcorp-cf-oac-01"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name        = "bazcorp-cf01"
    Environment = "Dev"
  }
}



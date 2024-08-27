provider "aws" {
  region = "ap-south-1"
}

resource "aws_s3_bucket" "bazcorp_s3" {
  bucket = "bazcorp-cf-01"

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
    Name        = "bazcorp-cf-01"
    Environment = "Dev"
  }
}




resource "aws_s3_bucket_public_access_block" "bazcorp_s3_pub" {
  bucket = aws_s3_bucket.bazcorp_s3.id

  block_public_acls       = false
  ignore_public_acls      = false
  block_public_policy     = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "public_policy" {
  bucket = aws_s3_bucket.bazcorp_s3.id

  policy = <<-EOF
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Sid": "PublicReadGetObject",
          "Effect": "Allow",
          "Principal": "*",
          "Action": [
        "s3:GetObject",
        "s3:GetObjectVersion"
        ],
          "Resource": "arn:aws:s3:::bazcorp-cf-01/*"
        }
      ]
    }
    EOF
}

resource "aws_s3_object" "image01" {
  bucket = aws_s3_bucket.bazcorp_s3.bucket
  key    = "6mb.jpg"
  source = "${path.module}/6mb.jpg"
  depends_on = [aws_s3_bucket_public_access_block.bazcorp_s3_pub]
}

resource "aws_s3_object" "image02" {
  bucket = aws_s3_bucket.bazcorp_s3.bucket
  key    = "15mb.jpg"
  source = "${path.module}/15mb.jpg"
  depends_on = [aws_s3_bucket_public_access_block.bazcorp_s3_pub]
}


#cdn--------------------------------------------------------------------------

resource "aws_cloudfront_distribution" "bazcorp_cdn01" {
  origin {
    domain_name = "bazcorp-cf-01.s3.ap-south-1.amazonaws.com"
    origin_id   = "S3-bazcorp-cf-01"

    s3_origin_config {
      origin_access_identity = ""
    }
  }

  default_cache_behavior {
    target_origin_id       = "S3-bazcorp-cf-01"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]

    compress = true

    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"

  }

  price_class = "PriceClass_All"

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "CF bazcorp-cf-01"

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

provider "aws" {
  region = "eu-central-1"
}

resource "aws_s3_bucket" "bazcorp_s3_web" {
  bucket = "bazcorp-s3-web01"

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
    Name        = "bazcorp-s3-web01"
    Environment = "Dev"
  }
}



resource "aws_s3_bucket_public_access_block" "bazcorp_s3_web_pub" {
  bucket = aws_s3_bucket.bazcorp_s3_web.id

  block_public_acls       = false
  ignore_public_acls      = false
  block_public_policy     = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "public_policy" {
  bucket = aws_s3_bucket.bazcorp_s3_web.id

  policy = <<-EOF
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Sid": "SourceIP",
          "Effect": "Deny",
          "Action": "s3:*",
          "Resource": [
            "arn:aws:s3:::bazcorp-s3-web01",
            "arn:aws:s3:::bazcorp-s3-web01/*"
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
          "Resource": "arn:aws:s3:::bazcorp-s3-web01/*"
        }
      ]
    }
    EOF
}

resource "aws_s3_object" "index_html" {
  bucket = aws_s3_bucket.bazcorp_s3_web.bucket
  key    = "index.html"
  source = "${path.module}/index.html"
  etag   = filemd5("${path.module}/index.html")
  content_type = "text/html"
}
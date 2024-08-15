provider "aws" {
  region = "eu-central-1"
}


resource "aws_s3_bucket" "s3_cors" {
  bucket = "bucket-cors-01"
  versioning {
    enabled = true
  }
  tags = {
    Name        = "bazcorp-s3-cors-01"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_public_access_block" "bazcorp_s3_pub" {
  bucket = aws_s3_bucket.s3_cors.id

  block_public_acls       = false
  ignore_public_acls      = false
  block_public_policy     = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "public_policy" {
  bucket = aws_s3_bucket.s3_cors.id

  policy = <<-EOF
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Sid": "SourceIP",
          "Effect": "Deny",
          "Action": "s3:*",
          "Resource": [
            "arn:aws:s3:::bucket-cors-01",
            "arn:aws:s3:::bucket-cors-01/*"
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
          "Resource": "arn:aws:s3:::bucket-cors-01/*"
        }
      ]
    }
    EOF
}


#-------------------------------------
resource "aws_s3_bucket" "s3_cors-dest" {
  bucket = "s3-cors-dest-01"
  versioning {
    enabled = true
  }
  tags = {
    Name        = "s3-cors-dest-01"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_public_access_block" "bazcorp_s3_pub-dest" {
  bucket = aws_s3_bucket.s3_cors-dest.id

  block_public_acls       = false
  ignore_public_acls      = false
  block_public_policy     = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "public_policy-dest" {
  bucket = aws_s3_bucket.s3_cors-dest.id

  policy = <<-EOF
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Sid": "SourceIP",
          "Effect": "Deny",
          "Action": "s3:*",
          "Resource": [
            "arn:aws:s3:::s3-cors-dest-01",
            "arn:aws:s3:::s3-cors-dest-01/*"
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
          "Resource": "arn:aws:s3:::s3-cors-dest-01/*"
        }
      ]
    }
    EOF
}

#-----------------------------------------

resource "aws_s3_bucket_cors_configuration" "s3-cors" {
  bucket = aws_s3_bucket.s3_cors-dest.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["PUT", "POST"]
    allowed_origins = ["https://s3-website-test.hashicorp.com"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }

  cors_rule {
    allowed_methods = ["GET"]
    allowed_origins = ["*"]
  }
}
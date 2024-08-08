provider "aws" {
  region = "eu-central-1"
}

resource "aws_s3_bucket" "bazcorp_s3" {
  #count  = 2
  bucket = "bazcorp-s3-01"
  acl    = "private"

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

  tags = {
    Name        = "bazcorp-s3-01"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "sse" {
  bucket = aws_s3_bucket.bazcorp_s3.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = "arn:aws:kms:eu-central-1:562464429819:key/65d8b5bc-4019-4e79-945f-ccc2745d5614"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "bazcorp_s3_pab" {
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
      "Id": "SourceIP",
      "Version": "2012-10-17",
      "Statement": [
        {
          "Sid": "SourceIP",
          "Action": "s3:*",
          "Effect": "Deny",
          "Resource": [
            "arn:aws:s3:::bazcorp-s3-01",
            "arn:aws:s3:::bazcorp-s3-01/*"
          ],
          "Condition": {
            "NotIpAddress": {
              "aws:SourceIp": [
                "5.152.58.63"
              ]
            }
          },
          "Principal": "*"
        }
      ]
    }
    EOF
}


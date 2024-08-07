provider "aws" {
  region = "eu-central-1"
}

resource "aws_s3_bucket" "bazcorp_s3" {
  count  = 2
  bucket = "bazcorp-s3-0${count.index + 1}"
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
    Name        = "bazcorp-s3-0${count.index + 1}"
    Environment = "Dev"
  }
}


resource "aws_s3_bucket_server_side_encryption_configuration" "sse" {
  count  = length(aws_s3_bucket.bazcorp_s3)
  bucket = aws_s3_bucket.bazcorp_s3[count.index].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = "arn:aws:kms:eu-central-1:562464429819:key/65d8b5bc-4019-4e79-945f-ccc2745d5614"
    }
  }
}

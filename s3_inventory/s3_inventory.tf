provider "aws" {
  region = "eu-central-1"
}

resource "aws_s3_bucket" "bazcorp_s3" {
  bucket = "bazcorp-s3-03"

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
    Name        = "bazcorp-s3-03"
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
          "Sid": "SourceIP",
          "Effect": "Deny",
          "Action": "s3:*",
          "Resource": [
            "arn:aws:s3:::bazcorp-s3-03",
            "arn:aws:s3:::bazcorp-s3-03/*"
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
          "Resource": "arn:aws:s3:::bazcorp-s3-03/*"
        }
      ]
    }
    EOF
}

resource "aws_s3_bucket_inventory" "bazcorp_s3_inventory" {
  bucket = aws_s3_bucket.bazcorp_s3.id
  name   = "bazcorp-s3-03-inv01"

  destination {
    bucket {
      bucket_arn = "arn:aws:s3:::bazcorp-inv03"
      format     = "CSV"

      encryption {
        sse_s3 {}
      }
    }
  }

  schedule {
    frequency = "Daily"
  }

  filter {
    prefix = ""
  }

  included_object_versions = "Current"
  
  optional_fields = [
    "Size",
    "LastModifiedDate",
    "StorageClass",
    "IntelligentTieringAccessTier",
  ]
}

resource "aws_s3_bucket_policy" "bazcorp_inventory_policy" {
  bucket = "bazcorp-inv03"

  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "InventoryAndAnalyticsExamplePolicy",
        "Effect": "Allow",
        "Principal": {
          "Service": "s3.amazonaws.com"
        },
        "Action": [
          "s3:PutObject"
        ],
        "Resource": [
          "arn:aws:s3:::bazcorp-inv03/*"
        ],
        "Condition": {
          "ArnLike": {
            "aws:SourceArn": "arn:aws:s3:::bazcorp-s3-03"
          },
          "StringEquals": {
            "aws:SourceAccount": "562464429819",
            "s3:x-amz-acl": "bucket-owner-full-control"
          }
        }
      }
    ]
  }
  EOF
}

provider "aws" {
  region = "eu-central-1"
}

provider "aws" {
  alias  = "northern"
  region = "eu-north-1"
}



resource "aws_s3_bucket" "bazcorp_s3_cors" {
  bucket = "bazcorp-s3-cors-01"

  versioning {
    enabled = true
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
    Name        = "bazcorp-s3-cors-01"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "sse" {
 bucket = aws_s3_bucket.bazcorp_s3_cors.id

  rule {
   apply_server_side_encryption_by_default {
     sse_algorithm     = "aws:kms"
      kms_master_key_id = "arn:aws:kms:eu-central-1:562464429819:key/65d8b5bc-4019-4e79-945f-ccc2745d5614"
    }
 }
}

resource "aws_s3_bucket_public_access_block" "bazcorp_s3_pub" {
  bucket = aws_s3_bucket.bazcorp_s3_cors.id

  block_public_acls       = false
  ignore_public_acls      = false
  block_public_policy     = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "public_policy" {
  bucket = aws_s3_bucket.bazcorp_s3_cors.id

  policy = <<-EOF
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Sid": "SourceIP",
          "Effect": "Deny",
          "Action": "s3:*",
          "Resource": [
            "arn:aws:s3:::bazcorp-s3-cors-01",
            "arn:aws:s3:::bazcorp-s3-cors-01/*"
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
          "Resource": "arn:aws:s3:::bazcorp-s3-cors-01/*"
        }
      ]
    }
    EOF
}

resource "aws_s3_bucket" "bazcorp_s3_cors_dest" {
  provider = aws.northern 
  bucket   = "bazcorp-s3-cors-02"

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = {
    Name        = "bazcorp-s3-cors-02"
    Environment = "Dev"
  }
}


resource "aws_iam_role" "replication_role" {
  name = "s3_replication_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}


resource "aws_iam_role_policy" "replication_policy" {
  role = aws_iam_role.replication_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetReplicationConfiguration",
          "s3:ListBucket",
          "s3:GetObjectVersion",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionTagging"
        ]
        Resource = [
          "arn:aws:s3:::bazcorp-s3-cors-01",
          "arn:aws:s3:::bazcorp-s3-cors-01/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags"
        ]
        Resource = [
          "arn:aws:s3:::bazcorp-s3-cors-02",
          "arn:aws:s3:::bazcorp-s3-cors-02/*"
        ]
      }
    ]
  })
}

resource "aws_s3_bucket_replication_configuration" "bazcorp_s3_replication" {
  depends_on = [aws_s3_bucket.bazcorp_s3_cors, aws_s3_bucket.bazcorp_s3_cors_dest]

  bucket = aws_s3_bucket.bazcorp_s3_cors.id


  role = aws_iam_role.replication_role.arn

  rule {
    id     = "replicate-log-to-north-1"
    status = "Enabled"

    filter {
      prefix = "log/"
    }

    destination {
      bucket        = aws_s3_bucket.bazcorp_s3_cors_dest.arn
      storage_class = "STANDARD"
    }

    delete_marker_replication {
      status = "Enabled"
    }
  }
}

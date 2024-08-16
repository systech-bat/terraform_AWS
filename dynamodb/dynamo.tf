provider "aws" {
  region = "eu-central-1"
}

resource "aws_dynamodb_table" "dynamo_table" {
  name           = "dynamo_table_01"
  billing_mode    = "PAY_PER_REQUEST"

  hash_key        = "key01"

  attribute {
    name = "key01"
    type = "S"
  }

 stream_enabled = true
 stream_view_type = "NEW_AND_OLD_IMAGES"

  tags = {
    Name = "dynamo_table_01"
  }
}

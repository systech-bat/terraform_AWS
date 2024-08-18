provider "aws" {
  region = "eu-central-1"
}

resource "aws_secretsmanager_secret" "db_secret02" {
  name = "postgres02_credentials"
}

resource "aws_secretsmanager_secret_version" "db_secret_version" {
  secret_id     = aws_secretsmanager_secret.db_secret02.id
  secret_string = jsonencode({
    username = "postgres01"
    password = var.db_password
  })
}

locals {
  db_credentials = jsondecode(aws_secretsmanager_secret_version.db_secret_version.secret_string)
}

resource "aws_db_instance" "postgresql" {
  identifier           = "pdb01"
  engine               = "postgres"
  engine_version       = "16.3"
  instance_class       = "db.t3.micro"
  allocated_storage    = 20
  max_allocated_storage = 500
  storage_type         = "gp3"

  username             = local.db_credentials.username
  password             = local.db_credentials.password
  parameter_group_name = "default.postgres16"

  publicly_accessible  = false
  multi_az             = false

  # Enabling storage encryption using AWS Secrets Manager default key
  storage_encrypted = true
  kms_key_id        = "arn:aws:kms:eu-central-1:562464429819:key/36560e02-0ec0-4ded-a8d6-d17c9c87d385"

  skip_final_snapshot = true
}

variable "db_password" {
  description = "The password for the PostgreSQL database"
  type        = string
  sensitive   = true
}

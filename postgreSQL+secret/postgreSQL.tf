provider "aws" {
  region = "eu-central-1"
}

resource "aws_secretsmanager_secret" "db_secret02" {
  name = "postgres02_credentials"
  tags = {
    Name = "secret-for_postgreSQL"
    Env  = "Dev"
  }
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

  storage_encrypted = true
  kms_key_id        = "arn:aws:kms:eu-central-1:562464429819:key/36560e02-0ec0-4ded-a8d6-d17c9c87d385"

  skip_final_snapshot = true
}

resource "aws_secretsmanager_secret_rotation" "db_secret02_rotation" {
  secret_id           = aws_secretsmanager_secret.db_secret02.id
  rotation_lambda_arn = "arn:aws:lambda:eu-central-1:562464429819:function:SecretsManageraurora01_secret_rotation"

  rotation_rules {
    automatically_after_days = 30
  }
}

resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  inline_policy {
    name = "lambda_secretsmanager_policy"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "secretsmanager:GetSecretValue",
            "secretsmanager:DescribeSecret",
            "secretsmanager:UpdateSecretVersionStage"
          ]
          Effect   = "Allow"
          Resource = aws_secretsmanager_secret.db_secret02.arn
        }
      ]
    })
  }
}

variable "db_password" {
  description = "pass for pdb01"
  type        = string
  sensitive   = true
}

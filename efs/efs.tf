provider "aws" {
  region = "eu-central-1"
}

resource "aws_efs_file_system" "efs01" {
  creation_token = "efs01"
  performance_mode = "generalPurpose"
  throughput_mode = "elastic"
  encrypted = true
 

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  lifecycle_policy {
    transition_to_primary_storage_class = "AFTER_1_ACCESS"
  }

  lifecycle_policy {
    transition_to_archive = "AFTER_180_DAYS"
  }

  tags = {
    Name = "efs01"
    Env  = "Dev"
  }
}

resource "aws_efs_backup_policy" "efs01_backup" {
  file_system_id = aws_efs_file_system.efs01.id

  backup_policy {
    status = "ENABLED"
  }
}

resource "aws_efs_mount_target" "efs01a" {
  file_system_id  = aws_efs_file_system.efs01.id
  subnet_id       = "subnet-03926859c7958fd90"
  security_groups = ["sg-059aaf3a73ded11c4"]
}

resource "aws_efs_mount_target" "efs01b" {
  file_system_id  = aws_efs_file_system.efs01.id
  subnet_id       = "subnet-0cf189dac65d8c8b5"
  security_groups = ["sg-059aaf3a73ded11c4"]
}

resource "aws_efs_mount_target" "efs01c" {
  file_system_id  = aws_efs_file_system.efs01.id
  subnet_id       = "subnet-021fc2ebc23791190"
  security_groups = ["sg-059aaf3a73ded11c4"]
}

resource "aws_efs_file_system_policy" "efs_policy" {
  file_system_id = aws_efs_file_system.efs01.id

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Id": "efs-policy-wizard-03844e5e-3269-4d97-9da5-df00e8f01bc1",
    "Statement": [
        {
            "Sid": "efs-statement-9236d3f9-6d07-42a5-b571-4ab9505cef0b",
            "Effect": "Allow",
            "Principal": {
                "AWS": "*"
            },
            "Action": [
                "elasticfilesystem:ClientRootAccess",
                "elasticfilesystem:ClientWrite",
                "elasticfilesystem:ClientMount"
            ],
            "Condition": {
                "Bool": {
                    "elasticfilesystem:AccessedViaMountTarget": "true"
                }
            }
        },
        {
            "Sid": "efs-statement-9be4ab95-b591-448d-afa0-94caf4059032",
            "Effect": "Deny",
            "Principal": {
                "AWS": "*"
            },
            "Action": "*",
            "Condition": {
                "Bool": {
                    "aws:SecureTransport": "false"
                }
            }
        }
    ]
}
POLICY
}

provider "aws" {
  region = "eu-central-1"
}

resource "aws_backup_vault" "vault03" {
  name = "vault03"
}

resource "aws_backup_plan" "daily_backup_plan" {
  name = "Daily"

  rule {
    rule_name         = "Daily_backup"
    target_vault_name = aws_backup_vault.vault03.name
    schedule          = "cron(30 20 * * ? *)"  
    start_window      = 60   
    completion_window = 180 

    lifecycle {
      cold_storage_after = 31
      delete_after       = 180
    }

    recovery_point_tags = {
      "Backup type" = "Daily01"
    }
  }
}

resource "aws_backup_selection" "daily_backup_selection" {
  name          = "Daily"
  iam_role_arn  = "arn:aws:iam::562464429819:role/service-role/AWSBackupDefaultServiceRole"
  plan_id       = aws_backup_plan.daily_backup_plan.id

  resources = ["*"]

   selection_tag {
    type  = "STRINGEQUALS"
    key   = "Backup"
    value = "daily"
  }
}
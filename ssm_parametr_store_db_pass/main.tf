provider "aws" {
  region = "eu-north-1"
}

resource "random_string" "rds_password" {
length = 12
special = true
override_special = "!@#$%"
}

resource "aws_ssm_parameter" "rds_password" {
  name = "/prod/mysql"
  description = "master password for RDS MySQL"
  type = "SecureString"
  value = random_string.rds_password.result
}

data "aws_ssm_parameter" "my_rds_password" {
  name = "/prod/mysql"

  depends_on = [aws_ssm_parameter.rds_password]
  }

  resource "aws_db_instance" "default" {
    identifier  = "prod-rds"
    allocated_storage    = 10
    engine               = "mysql"
    engine_version       = "5.7"
    instance_class       = "db.t3.micro"
    db_name                 = "Db1"
    username             = "administrator1"
    password             = "data.aws_ssm_parameter.my_rds_password"
    parameter_group_name = "default.mysql5.7"
    skip_final_snapshot  = true
    apply_immediately = true
  }

  output "rds_password" {
    value = data.aws_ssm_parameter.my_rds_password
    sensitive = true
  }

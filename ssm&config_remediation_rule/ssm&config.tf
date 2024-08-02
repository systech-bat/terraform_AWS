resource "aws_iam_role" "ssm_role" {
  name = "SSM02"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = [
            "ec2.amazonaws.com",
            "ssm.amazonaws.com"
          ]
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_policy_attachment" {
  role      = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonSSMAutomationRole"
}

resource "aws_iam_role_policy" "allow_pass_role" {
  name   = "AllowPassRole"
  role   = aws_iam_role.ssm_role.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "iam:PassRole"
        Resource = aws_iam_role.ssm_role.arn
      }
    ]
  })
}

resource "aws_config_config_rule" "approved_amis_by_id" {
  name = "approved-amis-by-id"

  source {
    owner             = "AWS"
    source_identifier = "APPROVED_AMIS_BY_ID"
  }

  input_parameters = jsonencode({
    amiIds = "ami-0e872aee57663ae2d"
  })
}

resource "aws_config_remediation_configuration" "approved_amis_by_id_remediation" {
  config_rule_name = "approved-amis-by-id"
  target_type      = "SSM_DOCUMENT"
  target_id        = "AWS-StopEC2Instance"
  target_version   = "1"
  automatic        = true

  parameter {
    name         = "AutomationAssumeRole"
    static_value = aws_iam_role.ssm_role.arn
  }

  parameter {
    name           = "InstanceId"
    resource_value = "RESOURCE_ID"
  }

  execution_controls {
    ssm_controls {
      concurrent_execution_rate_percentage = 100
      error_percentage                       = 1
    }
  }

  maximum_automatic_attempts = 3
  retry_attempt_seconds      = 60
}

provider "aws" {
  region = "eu-central-1"
}

resource "aws_opensearch_domain" "elk01" {
  domain_name    = "elk01"
  engine_version = "OpenSearch_2.13"

  cluster_config {
    instance_type            = "r6g.large.search"
    instance_count           = 3
    dedicated_master_enabled = true
    dedicated_master_type    = "m6g.large.search"
    zone_awareness_enabled   = true
    zone_awareness_config {
      availability_zone_count = 3
    }
  }

  ebs_options {
    ebs_enabled = true
    volume_type = "gp3"
    volume_size = 10
  }

  vpc_options {
    subnet_ids        = ["subnet-021fc2ebc23791190", "subnet-0cf189dac65d8c8b5", "subnet-03926859c7958fd90"]
    security_group_ids = ["sg-058a6319422a1c348"]
  }

  node_to_node_encryption {
    enabled = true
  }

  encrypt_at_rest {
    enabled = true
  }

  advanced_security_options {
    enabled                       = true
    internal_user_database_enabled = true
    master_user_options {
      master_user_name     = "olk01"
      master_user_password = "Pa$$w0rd"
    }
  }

  domain_endpoint_options {
    enforce_https = true
    tls_security_policy = "Policy-Min-TLS-1-2-2019-07"
  }

  access_policies = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "*"
      },
      "Action": "es:*",
      "Resource": "arn:aws:es:eu-central-1:562464429819:domain/elk01/*"
    }
  ]
}
POLICY

  tags = {
    Name        = "elk01"
    Environment = "Production"
  }
}

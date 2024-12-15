terraform {
    backend "s3" {
        profile     = "default"
        bucket      = "bazcorp-s3-01"
        encrypt     = true 
        key         = "terraform-states/terraform.tfstate"
        region      = "eu-central-1"
    }
    required_providers {
        aws = {
            version = "~> 3.0"
        }
    }
    required_version = ">=0.13"
}

provider "aws" {
    shared_credentials_file = "~/.aws/credentials"
    profile                 = "default"
    region                  = "eu-central-1"
}
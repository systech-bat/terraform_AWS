provider "aws" {}
data "aws_availability_zones" "working" {}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}


data "aws_vpcs" "my_vpcs" {
}

data "aws_vpc" "my_prod_vpc" {
  tags = {
    Name = "vpc1"
  }
}

resource "aws_subnet" "prod_subnet_1" {
  vpc_id = data.aws_vpc.my_prod_vpc.id
  availability_zone = data.aws_availability_zones.working.names[1]
  cidr_block = "172.31.254.0/24"
  tags = {
    Name = "subnet-1 in ${data.aws_availability_zones.working.names[2]}"
    Account = "Subnet in Account $[data.aws_caller_identity.current.account_id]"
    Region = data.aws_region.current.name
    }
}


resource "aws_subnet" "prod_subnet_2" {
  vpc_id = data.aws_vpc.my_prod_vpc.id
  availability_zone = data.aws_availability_zones.working.names[2]
  cidr_block = "172.31.253.0/24"
  tags = {
    Name = "subnet-2 in ${data.aws_availability_zones.working.names[2]}"
    Account = "Subnet in Account $[data.aws_caller_identity.current.account_id]"
    Region = data.aws_region.current.name
    }
}




output "prod_vpc_id" {
  value = data.aws_vpc.my_prod_vpc.id
}

output "prod_vpc_cidr" {
  value = data.aws_vpc.my_prod_vpc.cidr_block
}

output "aws_vpcs" {
  value = data.aws_vpcs.my_vpcs.ids
}



output "data_zones" {
  value = data.aws_availability_zones.working.names
}

output "data_aws_caller_identity" {
  value = data.aws_caller_identity.current.account_id
  }

output "data_aws_region_name" {
  value = data.aws_region.current.name
  }

output "data_aws_region_description" {
    value = data.aws_region.current.description
  }

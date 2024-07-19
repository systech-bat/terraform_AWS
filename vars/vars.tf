variable "region" {
  description = "Enter AWS region to deploy"
  type = string
  default = "eu-north-1"
}

variable "instance_type" {
  description = "Enter instance type"
  type = string
  default = "t3.micro"
}

variable "allow_ports" {
  description = "Enter allowed ports"
  type = list
  default = ["80", "443"]
  }

variable "enable_detailed_monitoring" {
  default = "true"
  type = bool
}
variable "common_tags" {
  description = "Tags for all resources"
  type = map
  default = {
    Owner = "BazCorp"
    Project = "Prod_v1"
    Enviroment = "dev_v1"
  }
}

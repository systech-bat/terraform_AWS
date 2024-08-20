provider "aws" {
  region = "eu-central-1"
}



#vpc's-----------------------------
resource "aws_vpc" "vpc_dev01" {
cidr_block = "10.0.0.0/24"
enable_dns_support = true
enable_dns_hostnames = true
tags = {
Name = "vpc_dev01"
}
}

resource "aws_vpc" "vpc_stage01" {
cidr_block = "20.0.0.0/24"
enable_dns_support = true
enable_dns_hostnames = true
tags = {
Name = "vpc_stage01"
}
}




#sub's--------------------
resource "aws_subnet" "pub_sub_vpc_dev01" {
vpc_id = aws_vpc.vpc_dev01.id
cidr_block = "10.0.0.0/24"
availability_zone = "eu-central-1a"
tags = {
Name = "Pub_sub1a"
}
}

resource "aws_subnet" "priv_sub_vpc_stage01" {
vpc_id = aws_vpc.vpc_stage01.id
cidr_block = "20.0.0.0/24"
availability_zone = "eu-central-1b"
tags = {
Name = "Priv_sub1b"
}
}



#IG----------------------------
resource "aws_internet_gateway" "ig_dev01" {
vpc_id = aws_vpc.vpc_dev01.id
tags = {
Name = "IG_dev0101"
}
}



#RT----------------------
resource "aws_route_table" "pub_rt_dev01" {
vpc_id = aws_vpc.vpc_dev01.id
route {
cidr_block = "0.0.0.0/0"
gateway_id = aws_internet_gateway.ig_dev01.id
}
tags = {
Name = "Pub_rt_dev01"
}
}

resource "aws_route_table_association" "public_subnet_association" {
subnet_id = aws_subnet.pub_sub_vpc_dev01.id
route_table_id = aws_route_table.pub_rt_dev01.id
}

resource "aws_route_table" "priv_rt_stage01" {
  vpc_id = aws_vpc.vpc_stage01.id
  tags = {
    Name = "Priv_rt_stage01"
  }
}

resource "aws_route_table_association" "private_subnet_association" {
  subnet_id = aws_subnet.priv_sub_vpc_stage01.id
  route_table_id = aws_route_table.priv_rt_stage01.id
}

resource "aws_route" "dev01_to_tgw" {
  route_table_id            = aws_route_table.pub_rt_dev01.id
  destination_cidr_block    = aws_vpc.vpc_stage01.cidr_block
  transit_gateway_id        = aws_ec2_transit_gateway.tgw01.id
}

resource "aws_route" "stage01_to_tgw" {
  route_table_id            = aws_route_table.priv_rt_stage01.id
  destination_cidr_block    = aws_vpc.vpc_dev01.cidr_block
  transit_gateway_id        = aws_ec2_transit_gateway.tgw01.id
}





#TGW-------------------------------------------------

resource "aws_ec2_transit_gateway" "tgw01" {
  tags = {
    Name = "tgw01"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "tgw_dev01" {
  transit_gateway_id = aws_ec2_transit_gateway.tgw01.id
  vpc_id             = aws_vpc.vpc_dev01.id
  subnet_ids         = [aws_subnet.pub_sub_vpc_dev01.id]

  tags = {
    Name = "TGW_for_dev01"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "tgw_stage01" {
  transit_gateway_id = aws_ec2_transit_gateway.tgw01.id
  vpc_id             = aws_vpc.vpc_stage01.id
  subnet_ids         = [aws_subnet.priv_sub_vpc_stage01.id]

  tags = {
    Name = "TGW_for_stage01"
  }
}

resource "aws_ec2_transit_gateway_route_table" "tgw01_rt" {
  transit_gateway_id = aws_ec2_transit_gateway.tgw01.id

  tags = {
    Name = "TGW01_rt"
  }
}

resource "aws_ec2_transit_gateway_route" "dev01_to_stage01" {
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw01_rt.id
  destination_cidr_block         = aws_vpc.vpc_stage01.cidr_block
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.tgw_stage01.id
}

resource "aws_ec2_transit_gateway_route" "stage01_to_dev01" {
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw01_rt.id
  destination_cidr_block         = aws_vpc.vpc_dev01.cidr_block
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.tgw_dev01.id
}






#SG------------------------------------------------
resource "aws_security_group" "sg_dev01" {
name = "sg_dev01"
description = "sg for dev01 env"
vpc_id = aws_vpc.vpc_dev01.id
ingress {
from_port = 22
to_port = 22
protocol = "tcp"
cidr_blocks = ["0.0.0.0/0"]
}
ingress {
from_port = 80
to_port = 80
protocol = "tcp"
cidr_blocks = ["0.0.0.0/0"]
}
ingress {
from_port = 443
to_port = 443
protocol = "tcp"
cidr_blocks = ["0.0.0.0/0"]
}
ingress {
from_port = 0
to_port = 65535
protocol = "tcp"
cidr_blocks = ["${aws_vpc.vpc_stage01.cidr_block}"]
}
egress {
from_port = 0
to_port = 0
protocol = "-1"
cidr_blocks = ["0.0.0.0/0"]
}
tags = {
Name = "sg_dev01"
}
}

resource "aws_security_group" "sg_stage01" {
name = "sg_stage01"
description = "sg for stage env"
vpc_id = aws_vpc.vpc_stage01.id
ingress {
from_port = 22
to_port = 22
protocol = "tcp"
cidr_blocks = ["0.0.0.0/0"]
}
ingress {
from_port = 80
to_port = 80
protocol = "tcp"
cidr_blocks = ["0.0.0.0/0"]
}
ingress {
from_port = 443
to_port = 443
protocol = "tcp"
cidr_blocks = ["0.0.0.0/0"]
}
ingress {
from_port = 0
to_port = 65535
protocol = "tcp"
cidr_blocks = ["${aws_vpc.vpc_dev01.cidr_block}"]
}

egress {
from_port = 0
to_port = 0
protocol = "-1"
cidr_blocks = ["0.0.0.0/0"]
}
tags = {
Name = "sg_stage01"
}
}




#NACL---------------------------------------------------

resource "aws_network_acl" "nacl_dev01" {
  vpc_id = aws_vpc.vpc_dev01.id


  ingress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "5.152.58.63/32"
    from_port  = 0
    to_port    = 0
  }

  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name = "acl_dev01"
  }
}



#EC2-------------------------------------------------------------------------

resource "aws_instance" "instance01" {
ami = "ami-0faab6bdbac9486fb"
instance_type = "t3.micro"
key_name = "eu_central_key"
vpc_security_group_ids = ["${aws_security_group.sg_dev01.id}"]
subnet_id = aws_subnet.pub_sub_vpc_dev01.id
associate_public_ip_address = true
user_data = <<-EOF
#!/bin/bash
apt -y update
apt -y install nginx
echo "Web01_pub_subnet" > /var/www/html/index.nginx-debian.html
sudo systemctl restart nginx
EOF
tags = {
Name = "instance01"
}
}


resource "aws_instance" "instance02" {
ami = "ami-0faab6bdbac9486fb"
instance_type = "t3.micro"
key_name = "eu_central_key"
vpc_security_group_ids = ["${aws_security_group.sg_stage01.id}"]
subnet_id = aws_subnet.priv_sub_vpc_stage01.id
associate_public_ip_address = false
user_data = <<-EOF
#!/bin/bash
apt -y update
apt -y install nginx
echo "Web02_priv_subnet" > /var/www/html/index.nginx-debian.html
sudo systemctl restart nginx
EOF
tags = {
Name = "instance02"
}
}

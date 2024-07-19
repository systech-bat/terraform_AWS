output "vpc_dev01_id" {
 value = aws_vpc.vpc_dev01.id
}

output "pub_sub_vpc_dev01_id" {
 value = aws_subnet.pub_sub_vpc_dev01.id
}

output "instance01_ip" {
 value = aws_instance.instance01.public_ip
}

output "vpc_stage01_id" {
 value = aws_vpc.vpc_stage01.id
}

output "priv_sub_vpc_stage01_id" {
 value = aws_subnet.priv_sub_vpc_stage01.id
}

output "TGW01_id" {
 value = aws_ec2_transit_gateway.tgw01.id
}

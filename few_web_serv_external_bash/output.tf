output "webserver_instance_id" {
  value = aws_instance.my_webs1.id
}

output "webserver_public_ip" {
  value = aws_eip.my_static_ip.public_ip
}

output "webserver_public_ip2" {
  value = aws_eip.my_static_ip2.public_ip
}

output "webserver_public_ip3" {
  value = aws_eip.my_static_ip3.public_ip
}

output "webserver_public_ip4" {
  value = aws_eip.my_static_ip4.public_ip
}

output "webserver_sg_id" {
  value = aws_security_group.my_webserver.id
}

output "webserver_sg_arn" {
  value = aws_security_group.my_webserver.arn
  description = "this is sec group arn"
}

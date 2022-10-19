


resource "null_resource" "example2" {
  provisioner "local-exec" {
    command = "ping -c 5 google.com >> ping.txt"
    }
}


resource "null_resource" "example1" {
  provisioner "local-exec" {
    command = "open WFH, '>>completed.txt' and print WFH scalar localtime"
    interpreter = ["perl", "-e"]
  }
}


resource "null_resource" "example3" {
  provisioner "local-exec" {
    command = "echo $name1 $name2 $name3 >> names.txt"
    environment = {
      name1 = "user1"
      name2 = "user2"
      name3 = "user3"
          }
        }
      }


  data "aws_ami" "latest_amazon_linux" {
  owners = ["amazon"]
  most_recent = true
  filter {
  name = "name"
  values = ["amzn2-ami-hvm-*-x86_64-gp2"]
        }
      }

  resource "aws_instance" "my_webs1" {
  ami = data.aws_ami.latest_amazon_linux.id # amazon linux ami
  instance_type = "t3.micro"
  provisioner "local-exec" {
    command = "echo hello from AWS"
  }
}

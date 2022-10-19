# security_groups
# launch configuration with auto AMI latest_amazon_linux
# Auto scailing group using 2 Availability zones
# Classic load Balancer in 2 Availability zones
#-----------------------------------------------

provider "aws" {
 region = "eu-north-1"
}

data "aws_availability_zones" "available" {}
data "aws_ami" "latest_amazon_linux" {
  owners = ["amazon"]
  most_recent = true
  filter {
    name = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

#---------------------------------------------------------

resource "aws_security_group" "my_webserver_dyn1" {
name        = "Dyn_sec_group1"
dynamic "ingress" {
  for_each = ["80", "443"]
  content {
    from_port        = ingress.value
    to_port          = ingress.value
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    name = "dyn_security_group1"
    owner = "bazcorp"
  }
}

#-----------------------------------------

resource "aws_launch_configuration" "web_launch_conf" {
  name          = "web_config_Hight-Available-Launch_config1"
  image_id      = data.aws_ami.latest_amazon_linux.id
  instance_type = "t3.micro"
  security_groups = [aws_security_group.my_webserver_dyn1.id]
  user_data = file("user_data.sh")

  lifecycle {
  create_before_destroy = true
  }
}

#-------------------------------------------------------------

resource  "aws_autoscaling_group" "autoscale_web1" {
  name = "web_config_Hight-Available-ASG1"
  launch_configuration = aws_launch_configuration.web_launch_conf.name
  min_size = 2
  max_size = 2
  min_elb_capacity = 2
  health_check_type = "ELB"
  load_balancers = [aws_lb.web_lb.name]

  tags = [
  {
    key = "Name"
    value = "WebServer-in-ASG"
    propagate_at_launch = true
  },
  {
    key = "Owner"
    value = "Bazcorp"
    propagate_at_launch = true
    }
  ]


  lifecycle {
  create_before_destroy = true
  }
}

#-----------------------------------------------------------------

resource "aws_lb" "web_lb" {
  name = "WebServer-ha-lb1"
  internal = false
    security_groups = [aws_security_group.my_webserver_dyn1.id]
  tags = {
    Name = "WebServer-Hight-Available-LB"
  }
}


#----------------------------------------------------

resource "aws_default_subnet" "default_az1" {
  availability_zone = "data.aws_availability_zones.available.names[0]"
}

resource "aws_default_subnet" "default_az2" {
  availability_zone = "data.aws_availability_zones.available.names[1]"
}

#------------------------------------------------

output "web_loadbalancer_url" {
  value = aws_lb.web_lb.dns_name
}

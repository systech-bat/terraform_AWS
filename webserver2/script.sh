#!/bin/bash
yum -y update
yum -y install httpd
myip=`curl http://169.254.169.254/latest/meta-data/local-ipv4`
echo "<h2>WebServer with IP: $myip</h2><br>Test server1"  >  /var/www/html/index.html
echo "<br><front color="blue">Test message1" >> /var/www/html/index.html
sudo service httpd start
chkconfig httpd on

#!/bin/bash
yum -y update
yum -y install httpd


myip=`curl http://169.254.169.254/latest/meta-data/local-ipv4`

cat <<EOF > /var/html/index.html>
<html>
<h2>build by BAZ <font color="red"> v0.12</font></h2><br>
owner ${f_name} ${l_name} <br>
%{for x in names~}
hello to ${x} from ${f_name}<br>
%{ endfor ~}

</html>
EOF
chkconfig httpd on

#!/bin/bash

yum install -y httpd

cat <<EOF > /var/www/html/index.html
<html>
<body>
<p>hostname is: $(hostname)</p>
</body>
</html>
EOF
chown -R apache:apache /var/www/html
systemctl enable httpd
systemctl start httpd

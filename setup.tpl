#!/bin/bash
### Based on https://dev.mysql.com/doc/refman/8.0/en/linux-installation-yum-repo.html ####
echo "User data Starting" > /var/log/aws_install.log 2>&1
echo "XXXXXXXXXXXXXXXXXX" >> /var/log/aws_install.log 2>&1

echo "Application configuration" >> /var/log/aws_install.log 2>&1
echo "XXXXXXXXXXXXXXXXXX" >> /var/log/aws_install.log 2>&1

echo "Clearing Cache" >> /var/log/aws_install.log 2>&1
sync; echo 3 > /proc/sys/vm/drop_caches

yum install python39 jq  -y >> /var/log/aws_install.log 2>&1
pip3.9 install  fastapi uvicorn mysql-connector-python requests tabulate >> /var/log/aws_install.log 2>&1

echo "Application configuration done" >> /var/log/aws_install.log 2>&1
echo "Clearing Cache" >> /var/log/aws_install.log 2>&1
sync; echo 3 > /proc/sys/vm/drop_caches

echo "Installing repo RPM">> /var/log/aws_install.log 2>&1
echo "XXXXXXXXXXXXXXXXXX" >> /var/log/aws_install.log 2>&1
rpm -Uvh https://repo.mysql.com/mysql80-community-release-el8-5.noarch.rpm >> /var/log/aws_install.log 2>&1

echo "Disbling native SQL" >> /var/log/aws_install.log 2>&1
echo "XXXXXXXXXXXXXXXXXX" >> /var/log/aws_install.log 2>&1

yum module -y disable mysql >> /var/log/aws_install.log 2>&1

echo "Installing mqsl community server" >> /var/log/aws_install.log 2>&1
echo "XXXXXXXXXXXXXXXXXX" >> /var/log/aws_install.log 2>&1

yum install mysql-community-server -y >> /var/log/aws_install.log 2>&1

echo "Starting mysql service" >> /var/log/aws_install.log 2>&1
echo "XXXXXXXXXXXXXXXXXX" >> /var/log/aws_install.log 2>&1

systemctl start mysqld >> /var/log/aws_install.log 2>&1

echo "Check the Port listening in on all interfaces for mysql" >> /var/log/aws_install.log 2>&1
echo "XXXXXXXXXXXXXXXXXX" >> /var/log/aws_install.log 2>&1
ss -tl | grep mysql >> /var/log/aws_install.log 2>&1

echo "Clearing Cache" >> /var/log/aws_install.log 2>&1
sync; echo 3 > /proc/sys/vm/drop_caches 

# Change the permission of the script folder >> /var/log/aws_install.log 2>&1
chmod -R 755 /home/centos/scripts >> /var/log/aws_install.log 2>&1

echo "Setting the password" >> /var/log/aws_install.log 2>&1
echo "XXXXXXXXXXXXXXXXXX" >> /var/log/aws_install.log 2>&1

pass=$(grep "A temporary password" /var/log/mysqld.log | awk '{print $NF}')
dbrootpass=`/home/centos/scripts/generate_randpass.py`
dbtoweruserpass=`/home/centos/scripts/generate_randpass.py`
echo "Old password : $pass" >>  /var/log/aws_install.log 2>&1
echo "Root password : $dbrootpass" >>  /var/log/aws_install.log 2>&1
echo "Toweruser password : $dbtoweruserpass" >>  /var/log/aws_install.log 2>&1

# Create a JSON object with password information
json_data='{"dbrootpass": "'"$dbrootpass"'", "dbtoweruserpass": "'"$dbtoweruserpass"'"}'

# Save the JSON object to a file
echo "$json_data" > /home/centos/scripts/config.json

echo "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY  '$dbrootpass';" | mysql -u root --password=$pass --connect-expired-password >> /var/log/aws_install.log 2>&1

echo "Creating a user 'toweruser' and granting permission" >> /var/log/aws_install.log 2>&1
echo "XXXXXXXXXXXXXXXXXX" >> /var/log/aws_install.log 2>&1

echo "CREATE USER 'toweruser'@'%' IDENTIFIED WITH mysql_native_password BY '$dbtoweruserpass';" | mysql -u root --password=$dbrootpass >> /var/log/aws_install.log 2>&1
echo "GRANT ALL PRIVILEGES ON *.* TO 'toweruser'@'%' WITH GRANT OPTION;FLUSH PRIVILEGES;" | mysql -u root --password=$dbrootpass >> /var/log/aws_install.log 2>&1

#echo "Creating a user 'towerro' and granting permission" >> /var/log/aws_install.log 2>&1
#echo "XXXXXXXXXXXXXXXXXX" >> /var/log/aws_install.log 2>&1

#echo "CREATE USER 'towerro'@'%' IDENTIFIED WITH mysql_native_password BY 'Readonly123@';" | mysql -u root --password='Toweruser123@' >> /var/log/aws_install.log 2>&1
#echo "GRANT SELECT ON *.* TO 'towerro'@'%';FLUSH PRIVILEGES;" | mysql -u root --password='Toweruser123@' >> /var/log/aws_install.log 2>&1

echo "Mysqld configuration done" >> /var/log/aws_install.log
echo "XXXXXXXXXXXXXXXXXX" >> /var/log/aws_install.log 2>&1

#echo "Application configuration" >> /var/log/aws_install.log 2>&1
#echo "XXXXXXXXXXXXXXXXXX" >> /var/log/aws_install.log 2>&1

#echo "Clearing Cache" >> /var/log/aws_install.log 2>&1
#sync; echo 3 > /proc/sys/vm/drop_caches 

#yum install python39 -y >> /var/log/aws_install.log 2>&1
#pip3.9 install  fastapi uvicorn >> /var/log/aws_install.log 2>&1

#echo "Application configuration done" >> /var/log/aws_install.log 2>&1
echo "Clearing Cache" >> /var/log/aws_install.log 2>&1
sync; echo 3 > /proc/sys/vm/drop_caches 

echo "Starting the FASTAPI and change the permission of the scripts" >> /var/log/aws_install.log 2>&1
echo "XXXXXXXXXXXXXXXXXX" >> /var/log/aws_install.log 2>&1
cd /home/centos/scripts ; /usr/local/bin/uvicorn app:app --host 0.0.0.0 --port 80 &  >> /var/log/aws_install.log 2>&1
chmod -R 755 /home/centos/scripts
chmod 600 /home/centos/scripts/config.json /home/centos/scripts/dbroot /home/centos/scripts/toweruser

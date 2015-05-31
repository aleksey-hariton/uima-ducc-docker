#!/bin/sh
#
#
## SSH 
service ssh start
chmod 700 /home/ducc/.ssh
chmod 600 /home/ducc/.ssh/id_rsa
chmod +r /home/ducc/.ssh/id_rsa.pub
cp /home/ducc/.ssh/id_rsa.pub /home/ducc/.ssh/authorized_keys
echo "StrictHostKeyChecking=no" > /home/ducc/.ssh/config

## The same for root user
cp -Rf /home/ducc/.ssh/ /root/
chown -Rf root.root /home/ducc/.ssh/


# UIMA DUCC installation
cd /home/ducc/ && tar xzf uima-ducc-1.1.0-bin.tar.gz && mv apache-uima-ducc-1.1.0/* /home/ducc/apache-uima-ducc/
rm -Rf /home/ducc/apache-uima-ducc-1.1.0/

cd /home/ducc/apache-uima-ducc/admin/ && /home/ducc/apache-uima-ducc/admin/ducc_post_install
chown ducc.ducc -Rf /home/ducc/

# Prepare ducc_ling file
chown root.ducc /home/ducc/apache-uima-ducc/admin/ducc_ling
chmod 700 /home/ducc/apache-uima-ducc/admin/
chmod 4750 /home/ducc/apache-uima-ducc/admin/ducc_ling

# check_ducc will prepare ducc_ling.version file
export LOGNAME="ducc"
su - ducc -c "/home/ducc/apache-uima-ducc/admin/check_ducc"

# Starting ducc
su - ducc -c "/home/ducc/apache-uima-ducc/admin/start_ducc"

# Daemonize Docker container
while true; do sleep 1; done

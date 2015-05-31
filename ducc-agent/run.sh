#!/bin/sh
#
#
service ssh start
chmod 700 /home/ducc/.ssh
chmod 600 /home/ducc/.ssh/id_rsa
chmod +r /home/ducc/.ssh/id_rsa.pub
cp /home/ducc/.ssh/id_rsa.pub /home/ducc/.ssh/authorized_keys
echo "StrictHostKeyChecking=no" > /home/ducc/.ssh/config

# UIMA DUCC installation
cd /home/ducc/ && tar xzf uima-ducc-1.1.0-bin.tar.gz && mv apache-uima-ducc-1.1.0/* /home/ducc/apache-uima-ducc/
rm -Rf /home/ducc/apache-uima-ducc-1.1.0/
cd /home/ducc/apache-uima-ducc/admin/ && /home/ducc/apache-uima-ducc/admin/ducc_post_install

# For Docker-compose head will be IP address of "head_N"
# For pure Docker simple "head"
head=`cat /etc/hosts | awk '/head_? /{print $1}'`
[ "$head" = "" ] && head="head"

# Setup ducc.head
sed -i "s/ducc.head = .*/ducc.head = $head/" /home/ducc/apache-uima-ducc/resources/ducc.properties
chown ducc.ducc -Rf /home/ducc/

# Setup of ducc_ling file
chown root.ducc /home/ducc/apache-uima-ducc/admin/ducc_ling
chmod 700 /home/ducc/apache-uima-ducc/admin/
chmod 4750 /home/ducc/apache-uima-ducc/admin/ducc_ling

# check_ducc will prepare ducc_ling.version file
export LOGNAME="ducc"
su - ducc -c "/home/ducc/apache-uima-ducc/admin/check_ducc"

# Add new agent node on DUCC head server and startup all nodes
host=`hostname -f`
ip=`ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p'`
su - ducc -c "ssh root@$head 'echo $ip $host >> /etc/hosts'"
su - ducc -c "ssh $head 'echo \"\" >> /home/ducc/apache-uima-ducc/resources/ducc.nodes'"
su - ducc -c "ssh $head 'echo \"$host\" >> /home/ducc/apache-uima-ducc/resources/ducc.nodes'"
su - ducc -c "ssh $head '/home/ducc/apache-uima-ducc/admin/start_ducc'"

# Daemonize Docker container
while true; do sleep 1; done

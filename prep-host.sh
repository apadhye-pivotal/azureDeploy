#!/bin/bash

IPADDR=$1
HOSTNAME=$2
SERVERS=$3
APITOKEN=$4
SSHPRIVKEY=$5
IP_PREFIX=$6
SERVER_IP_BASE=$7

# Enable IP<->hostname mapping
echo -e "\n${IPADDR} ${HOSTNAME}" | tee --append /etc/hosts

# Allow passwordless sudo
sed -i -e 's/ALL$/NOPASSWD: ALL/' /etc/sudoers.d/waagent

# Don't require TTY for sudo
sed -i -e 's/^Defaults    requiretty/#Defaults    requiretty/' /etc/sudoers

# Allow loopback SSH
ssh-keyscan ${HOSTNAME} | tee --append /etc/ssh/ssh_known_hosts

# Generate ssh folder/key with right permissions, then overwrite
ssh-keygen -P "" -f /root/.ssh/id_rsa
echo -e "${SSHPRIVKEY}" > /root/.ssh/id_rsa
rm -f /root/.ssh/id_rsa.pub

# Generate ssh folder/key with right permissions, then overwrite
su gfadmin -c 'ssh-keygen -P "" -f /home/gfadmin/.ssh/id_rsa'
echo -e "${SSHPRIVKEY}" > /home/gfadmin/.ssh/id_rsa
rm -f /home/gfadmin/.ssh/id_rsa.pub

# Make sure root has passwordless SSH as well
cp /home/gfadmin/.ssh/authorized_keys /root/.ssh/
chown root:root /root/.ssh/authorized_keys

# Disable selinux
sed -ie "s|SELINUX=enforcing|SELINUX=disabled|" /etc/selinux/config
setenforce 0


# Install an configure fail2ban for the script kiddies
yum install epel-release -y
yum install fail2ban -y

cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local

sed -ie "s|ignoreip = 127\.0\.0\.1/8|ignoreip = 127.0.0.1/8\nignoreip = ${IPADDR}/24|" /etc/fail2ban/jail.local

echo -e "\n\n
[ssh-iptables]
enabled  = true
filter   = sshd
action   = iptables[name=SSH, port=ssh, protocol=tcp]
logpath  = /var/log/secure
maxretry = 5
" >> /etc/fail2ban/jail.local 

service fail2ban start
chkconfig fail2ban on

curl -o /home/gfadmin/jdk-8u72-linux-x64.tar.gz -k -L -H "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/8u72-b15/jdk-8u72-linux-x64.tar.gz"    
chown gfadmin:gfadmin /home/gfadmin/jdk-8u72-linux-x64.tar.gz

curl -o /home/gfadmin/pivotal-gemfire-9.0.1.zip -L -H "Authorization: Token ${APITOKEN}" "https://network.pivotal.io/api/v2/products/pivotal-gemfire/releases/3464/product_files/10771/download"
chown gfadmin:gfadmin /home/gfadmin/pivotal-gemfire-9.0.1.zip

tar xzf /home/gfadmin/jdk-8u72-linux-x64.tar.gz -C /opt/
unzip gfadmin:gfadmin /home/gfadmin/pivotal-gemfire-9.0.1.zip -d /opt/

echo 'export PATH=/opt/jdk1.8.0_72/bin/:${PATH}' >> /home/gfadmin/.bashrc
echo 'export PATH=/opt/pivotal-gemfire-9.0.1/bin/:${PATH}' >> /home/gfadmin/.bashrc
echo 'export JAVA_HOME=/opt/jdk1.8.0_72/' >> /home/gfadmin/.bashrc

if [[ "${HOSTNAME}" == *"mdw"* ]] ; then
    # Update system host file with segment hosts
    python -c "print '\n'.join(['10.4.0.{0} {1}'.format(ip, 'sdw{0}'.format(n+1)) for n, ip in enumerate(range(${SERVER_IP_BASE}, ${SERVER_IP_BASE} + ${SERVERS}))])" >> /etc/hosts

else
    # Run the prep-segment.sh
fi
    

# Disable strict host checking for cluster hosts
for h in `grep sdw /etc/hosts | cut -f2 -d ' '` ; do echo -e "\nHost ${h}\n  StrictHostKeyChecking no\n" | tee --append /etc/ssh/ssh_config ; done ;

# Push host file
for h in `grep sdw /etc/hosts | cut -f2 -d ' '` ; do scp /etc/hosts ${h}:/etc/ ; done ;

# Install Hyper-V Linux Integration Services
yum install microsoft-hyper-v -y

echo "Done"

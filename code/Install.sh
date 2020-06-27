#!/bin/bash

# Need to run these after login...  UPDATE to MASTER SOON!
#curl -o https://raw.githubusercontent.com/fgamgee/Jitsi-Meet-Secure-Server/master/code/Install.sh
#chmod +x Install.sh
#sudo ./Install.sh

#Set up for debugging, from https://wiki.bash-hackers.org/scripting/debuggingtips
set -x
export PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
echo "Welcome to installation of private and secure Jitsi Meet server for Ubuntu 18.04"

# install firewall

iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT DROP
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -s 127.0.0.0/8 -j DROP
iptables -A INPUT -p tcp -m state --state ESTABLISHED -j ACCEPT
iptables -A INPUT -p udp -m state --state ESTABLISHED -j ACCEPT
iptables -A INPUT -p icmp -m state --state ESTABLISHED -j ACCEPT
iptables -A INPUT -p tcp -m tcp --dport 22 -m state --state NEW -j ACCEPT
#Below ports not needed
#iptables -A INPUT -p udp -m udp --dport 68 -m state --state NEW -j ACCEPT
#iptables -A INPUT -p udp -m udp --dport 123 -m state --state NEW -j ACCEPT
#iptables -A INPUT -p udp -m udp --dport 323 -m state --state NEW -j ACCEPT
iptables -A INPUT -p tcp -m tcp --dport 443 -j ACCEPT
iptables -A INPUT -p tcp -m tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp -m tcp --dport 4443 -j ACCEPT
iptables -A INPUT -p udp -m udp --dport 10000 -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT
iptables -A OUTPUT -p tcp -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -p udp -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -p icmp -m state --state NEW,ESTABLISHED -j ACCEPT

#Now get repositories and packages I will need.
apt -y update
apt -y install apt-transport-https
apt-add-repository -y universe
apt -y update

#Now save the iptables rules so they stay on reboot.
apt-get -y install iptables-persistent
netfilter-persistent save
netfilter-persistent reload

#Jitsi-Meet install https://aws.amazon.com/blogs/opensource/getting-started-with-jitsi-an-open-source-web-conferencing-solution/

echo 'deb https://download.jitsi.org stable/' >> /etc/apt/sources.list.d/jitsi-stable.list
wget -qO - https://download.jitsi.org/jitsi-key.gpg.key | apt-key add -
apt-get update
apt-get -y install jitsi-meet

#Let's Encrypt certificate
/usr/share/jitsi-meet/scripts/install-letsencrypt-cert.sh

# Make keys needed for secure DH key exchange - 2048 is OK. Can do 4096 - but
# it takes long time...
# Moved to Ansible
# openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048

#Install Ansible
apt install -y ansible
cd /etc/ansible/
# Get configurations of jitsi
curl -o /etc/ansible/Jitsi_login_req_config.yml https://raw.githubusercontent.com/fgamgee/Jitsi-Meet-Secure-Server/master/code/Jitsi_login_req_config.yml
curl -o /etc/ansible/Jitsi_TLS_DH_config.yml https://raw.githubusercontent.com/fgamgee/Jitsi-Meet-Secure-Server/master/code/Jitsi_TLS_DH_config.yml

# Run configuration for Jitsi
ansible-playbook -v Jitsi_login_req_config.yml
ansible-playbook -v Jitsi_TLS_DH_config.yml
#Get Ansible playbook for CIS hardening -
# From https://cloudsecuritylife.com/cis-ubuntu-script-to-automate-server-hardening/
sh -c "echo '- src: https://github.com/florianutz/Ubuntu1804-CIS.git' >> /etc/ansible/requirements.yml"

ansible-galaxy install -p roles -r /etc/ansible/requirements.yml
# Make role - don't like this method.  Update needed.
cat > /etc/ansible/harden.yml <<EOF
- name: Harden Server
  hosts: localhost
  connection: local
  become: yes

  roles:
    - Ubuntu1804-CIS

EOF
# Change defaults needed for Jitsi Meet - don't like this method.  Update needed.
# X Windows is not installed, as can be checked with  dpkg -l xserver-xorg*
# but Ansible xwindows task removes x11 which Jitsi does need
# Needs to have dummy telnet package installed and telnet removed - but Coturn
# has a dependency of telnet (but it is only used for debugging).
# I currently use iptables.
# Rule 4.3 is logrotate, which prosody does not like...  get rid of logging is
# a privacy goal.
cat > /etc/ansible/roles/Ubuntu1804-CIS/vars/main.yml  <<EOF
---
# vars file for Ubuntu1804-CIS
ubuntu1804cis_xwindows_required: true
ubuntu1804cis_telnet_required: true
ubuntu1804cis_firewall: iptables
ubuntu1804cis_rule_4_3: false

EOF

cd /etc/ansible/

ansible-playbook /etc/ansible/harden.yml

set +x
printf "\n"
printf "Let's set up a host and password for meetings.\n"
printf "\n"
thehost=$(grep JVB_HOSTNAME= /etc/jitsi/videobridge/config | sed 's/^.*=//')
#  below not POSIX compliant, depends on bash, but convenient...
read -p "Username for host of meeting: " username
read -s -p "Password: " password
echo
prosodyctl register $username $thehost $password

# Make add_user.sh- don't like this method.  Update needed.  But it was quick...
cat > ./add_host.sh <<EOF
#!/bin/bash
thehost=$(grep JVB_HOSTNAME= /etc/jitsi/videobridge/config | sed 's/^.*=//')
echo \$thehost
#  below not POSIX compliant, depends on bash, but convenient...
read -p "Username for host of meeting: " username
read -s -p "Create a Password: " password
echo
prosodyctl register \$username \$thehost \$password

EOF

chmod +x ./add_host.sh

#Stop services and restart them, avoids a reboot.
printf "Restarting Services\n"
systemctl stop coturn.service
systemctl stop jitsi-videobridge2.service
systemctl stop nginx.service
systemctl stop prosody.service
systemctl stop jicofo.service
systemctl start coturn.service
systemctl start jitsi-videobridge2.service
systemctl start nginx.service
systemctl start prosody.service
systemctl start jicofo.service

printf "Installation is complete! You can test Jitsi now by starting a meeting.\n"
printf "However, to apply security patches you need to stop, and then start your instance.\n"
printf "To add more meeting hosts, type 'sudo ./add_host'\n"

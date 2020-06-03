#!/bin/bash

# Need to run these after login...
#curl -o Install.sh https://raw.githubusercontent.com/fgamgee/Jitsi-Meet-Secure-Server/Install_script/Install.sh
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

#Install Ansible
apt install -y ansible
#Get Ansible playbook for CIS hardening -
# From https://cloudsecuritylife.com/cis-ubuntu-script-to-automate-server-hardening/
sh -c "echo '- src: https://github.com/florianutz/Ubuntu1804-CIS.git' >> /etc/ansible/requirements.yml"
cd /etc/ansible/
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
#TBD to be automated.

#// For ansible, have to modify  https://github.com/florianutz/Ubuntu1804-CIS
#To run the tasks in this repository, first create this file one level above the repository (i.e. the playbook .yml and the directory Ubuntu1804-CIS should be next to each other), then review the file defaults/main.yml and disable any rule/section you do not wish to execute.

#Set to 'true' if X Windows is needed in your environment - issue with ansible
# there is no X Windows installed anyway, check with dpkg -l xserver-xorg*


#ubuntu1804cis_xwindows_required: no  change to true


#Coturn and jitsi-meet-turnserver depend on the telnet package, so that has to be modified too.

# Service configuration booleans set true to keep service
#ubuntu1804cis_telnet_server: false
# ubuntu1804cis_telnet_required: true

#Should I change Firewall to iptables?  Yes....maybe?

#ubuntu1804cis_firewall: firewalld
#ubuntu1804cis_firewall: iptables

#Need to turn off 4.3 logrotate in ansible.

#ansible-playbook /etc/ansible/harden.yml

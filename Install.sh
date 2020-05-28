#!/bin/bash

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
iptables -A INPUT -p udp -m udp --dport 68 -m state --state NEW -j ACCEPT
iptables -A INPUT -p udp -m udp --dport 123 -m state --state NEW -j ACCEPT
iptables -A INPUT -p udp -m udp --dport 323 -m state --state NEW -j ACCEPT
iptables -A INPUT -p tcp -m tcp --dport 443 -j ACCEPT
iptables -A INPUT -p tcp -m tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp -m tcp --dport 4443 -j ACCEPT
iptables -A INPUT -p udp -m udp --dport 10000 -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT
iptables -A OUTPUT -p tcp -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -p udp -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -p icmp -m state --state NEW,ESTABLISHED -j ACCEPT

#Now save the iptables rules so they stay on reboot.
apt-get install iptables-persistent
netfilter-persistent save
netfilter-persistent reload


#Install Ansible
apt install -y ansible
#Get Ansible playbook for CIS hardening -
# From https://cloudsecuritylife.com/cis-ubuntu-script-to-automate-server-hardening/
sh -c "echo '- src: https://github.com/florianutz/Ubuntu1804-CIS.git' >> /etc/ansible/requirements.yml"
cd /etc/ansible/
ansible-galaxy install sudo iptables -P roles -r /etc/ansible/requirements.yml
# Make role - don't like this method.  Update needed.
#sudo sh -c "cat > /etc/ansible/harden.yml <<EOF
#- name: Harden Server
#  hosts: localhost
#  connection: local
#  become: yes

#  roles:
#    - Ubuntu1804-CIS

#EOF
#"
#ansible-playbook /etc/ansible/harden.yml

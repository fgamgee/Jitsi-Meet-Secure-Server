#!/bin/bash
echo "Welcome to installation of private and secure Jitsi Meet server for Ubuntu 18.04"
# install firewall

sudo iptables -P INPUT DROP
sudo iptables -P FORWARD DROP
sudo iptables -P OUTPUT DROP
sudo iptables -A INPUT -i lo -j ACCEPT
sudo iptables -A INPUT -s 127.0.0.0/8 -j DROP
sudo iptables -A INPUT -p tcp -m state --state ESTABLISHED -j ACCEPT
sudo iptables -A INPUT -p udp -m state --state ESTABLISHED -j ACCEPT
sudo iptables -A INPUT -p icmp -m state --state ESTABLISHED -j ACCEPT
sudo iptables -A INPUT -p tcp -m tcp --dport 22 -m state --state NEW -j ACCEPT
sudo iptables -A INPUT -p udp -m udp --dport 68 -m state --state NEW -j ACCEPT
sudo iptables -A INPUT -p udp -m udp --dport 123 -m state --state NEW -j ACCEPT
sudo iptables -A INPUT -p udp -m udp --dport 323 -m state --state NEW -j ACCEPT
sudo iptables -A INPUT -p tcp -m tcp --dport 443 -j ACCEPT
sudo iptables -A INPUT -p tcp -m tcp --dport 80 -j ACCEPT
sudo iptables -A INPUT -p tcp -m tcp --dport 4443 -j ACCEPT
sudo iptables -A INPUT -p udp -m udp --dport 10000 -j ACCEPT
sudo iptables -A OUTPUT -o lo -j ACCEPT
sudo iptables -A OUTPUT -p tcp -m state --state NEW,ESTABLISHED -j ACCEPT
sudo iptables -A OUTPUT -p udp -m state --state NEW,ESTABLISHED -j ACCEPT
sudo iptables -A OUTPUT -p icmp -m state --state NEW,ESTABLISHED -j ACCEPT
sudo netfilter-persistent save


#Install Ansible
sudo apt install -y ansible
#Get Ansible playbook for CIS hardening -
# From https://cloudsecuritylife.com/cis-ubuntu-script-to-automate-server-hardening/
sudo sh -c "echo '- src: https://github.com/florianutz/Ubuntu1804-CIS.git' >> /etc/ansible/requirements.yml"
cd /etc/ansible/
sudo ansible-galaxy install sudo iptables -P roles -r /etc/ansible/requirements.yml
# Make role - don't like this method.  Update needed.
sudo sh -c "cat > /etc/ansible/harden.yml <<EOF
- name: Harden Server
  hosts: localhost
  connection: local
  become: yes

  roles:
    - Ubuntu1804-CIS

EOF
"
sudo ansible-playbook /etc/ansible/harden.yml

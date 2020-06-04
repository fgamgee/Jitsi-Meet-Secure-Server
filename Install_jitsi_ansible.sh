#!/bin/bash

# Need to run these after login...
#curl -o Install_jitsi_ansible.sh https://raw.githubusercontent.com/fgamgee/Jitsi-Meet-Secure-Server/Install_script/Install_jitsi_ansible.sh
#chmod +x Install_jitsi_ansible.sh
#sudo ./Install_jitsi_ansible.sh
#

#Set up for debugging, from https://wiki.bash-hackers.org/scripting/debuggingtips
set -x
export PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
echo "Welcome to installation of private and secure Jitsi Meet server for Ubuntu 18.04"


# First, setup firewall.

iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT DROP
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -s 127.0.0.0/8 -j DROP
iptables -A INPUT -p tcp -m state --state ESTABLISHED -j ACCEPT
iptables -A INPUT -p udp -m state --state ESTABLISHED -j ACCEPT
iptables -A INPUT -p icmp -m state --state ESTABLISHED -j ACCEPT
iptables -A INPUT -p tcp -m tcp --dport 22 -m state --state NEW -j ACCEPT
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

#Install ansible
apt install -y ansible

# Make roles - don't like this method.  Update needed.
cat > /etc/ansible/jitsi.yml <<EOF
- name: Configure jitsi-meet server.
  hosts: localhost
  connection: local
  vars:
    # Change this to match the DNS entry for your host IP.
    jitsi_meet_server_name: mrsunderhill.net
    DNS_email_address: kevinwilson@gatech.edu

  roles:
    - role: geerlingguy.certbot
      become: yes
      certbot_create_if_missing: true
      # Change this to variable
      certbot_admin_email: "{{ DNS_email_address }}"
      certbot_certs:
        - domains:
            - "{{ jitsi_meet_server_name }}"
      certbot_create_standalone_stop_services: []

    - role: udelarinterior.jitsi_meet
      jitsi_meet_ssl_cert_path: "/etc/letsencrypt/live/{{ jitsi_meet_server_name }}/fullchain.pem"
      jitsi_meet_ssl_key_path: "/etc/letsencrypt/live/{{ jitsi_meet_server_name }}/privkey.pem"
      become: yes
      tags: jitsi

EOF

ansible-galaxy install udelarinterior.jitsi_meet
ansible-galaxy install geerlingguy.certbot

cd /etc/ansible/

ansible-playbook /etc/ansible/jitsi.yml

#Make key for secure DH exchange.
openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048

#!/bin/bash

# Standalone Installation
# Need to run these after login... (Either standalone or master in curl line, depending on stable or unstable)
#curl -o Install.sh https://raw.githubusercontent.com/fgamgee/Jitsi-Meet-Secure-Server/master/code/Install_standalone.sh
#curl -o Install.sh https://raw.githubusercontent.com/fgamgee/Jitsi-Meet-Secure-Server/standalone/code/Install_standalone.sh
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
# Disable SSH port, login with a keyboard.
#iptables -A INPUT -p tcp -m tcp --dport 22 -m state --state NEW -j ACCEPT
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

#Ubuntu 18.04 uses nginx 1.14.0 as of June 26, 2020.  It has some CVE's.  update
#I just cannot get this way to work....
# I think, because of this: https://stackoverflow.com/questions/17413526/nginx-missing-sites-available-directory#17415606
# As the issue is sites-available directory is not there...  LOVE for someone else to fix it,
# as this would be preferred.  For now, will stick to the ppa repository below.
#Update the nginx packages
#cat > /etc/apt/sources.list.d/nginx.list  <<EOF
#deb https://nginx.org/packages/ubuntu/ bionic nginx
#deb-src https://nginx.org/packages/ubuntu/ bionic nginx
#EOF

# Need to add the nginx key too.  See https://www.nginx.com/resources/wiki/start/topics/tutorials/install/
# If this fails, see what the key is, and replace ABF5BD827BD9BF62
# Err:6 https://nginx.org/packages/ubuntu bionic InRelease
#  The following signatures couldn't be verified because the public key is not available: NO_PUBKEY ABF5BD827BD9BF62
#
#sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys ABF5BD827BD9BF62
# Try installing nginx before Jitsi
#sudo apt-get update
#sudo apt-get install nginx

# This works, but ppa is untrusted and only gets you to 1.16.1 nginx
add-apt-repository ppa:nginx/stable
apt-get update

#add prosody repository and key.
echo 'deb https://packages.prosody.im/debian bionic main' >> /etc/apt/sources.list.d/prosody.list
wget -qO - https://prosody.im/files/prosody-debian-packages.key | apt-key add -
apt update

#Jitsi-Meet install https://aws.amazon.com/blogs/opensource/getting-started-with-jitsi-an-open-source-web-conferencing-solution/

echo 'deb https://download.jitsi.org stable/' >> /etc/apt/sources.list.d/jitsi-stable.list
wget -qO - https://download.jitsi.org/jitsi-key.gpg.key | apt-key add -
# Need to add the nginx key too.  See https://www.nginx.com/resources/wiki/start/topics/tutorials/install/
# If this fails, see what the key is, and replace ABF5BD827BD9BF62
# Err:6 https://nginx.org/packages/ubuntu bionic InRelease
#  The following signatures couldn't be verified because the public key is not available: NO_PUBKEY ABF5BD827BD9BF62
#
#sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys ABF5BD827BD9BF62
apt-get update
apt-get -y install jitsi-meet

#Let's Encrypt certificate - note, you will see this in the logs, because logging is
# not yet disabled, but I think that is fine.
/usr/share/jitsi-meet/scripts/install-letsencrypt-cert.sh

#Install Ansible
apt install -y ansible
cd /etc/ansible/
# Get configurations of jitsi - Need UPDATE from standalone to MASTER when merged!
curl -o /etc/ansible/Jitsi_login_req_config.yml https://raw.githubusercontent.com/fgamgee/Jitsi-Meet-Secure-Server/master/code/Jitsi_login_req_config.yml
curl -o /etc/ansible/Jitsi_TLS_DH_config.yml https://raw.githubusercontent.com/fgamgee/Jitsi-Meet-Secure-Server/master/code/Jitsi_TLS_DH_config.yml
curl -o /etc/ansible/Jitsi_no_logging.yml https://raw.githubusercontent.com/fgamgee/Jitsi-Meet-Secure-Server/master/code/Jitsi_no_logging.yml

# Run configuration for Jitsi
ansible-playbook -v Jitsi_login_req_config.yml
ansible-playbook -v Jitsi_TLS_DH_config.yml
# This is used to disable logging, comment out if you want logging.
ansible-playbook -v Jitsi_no_logging.yml

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
# Section 5_2_* is all SSH configuration

cat > /etc/ansible/roles/Ubuntu1804-CIS/vars/main.yml  <<EOF
---
# vars file for Ubuntu1804-CIS
ubuntu1804cis_xwindows_required: true
ubuntu1804cis_telnet_required: true
ubuntu1804cis_firewall: iptables
#logrotate seems to break prosody
ubuntu1804cis_rule_4_3: false
# Below is to disable Auditing and logging, to maintain privacy -
# no record on system if compromised - but no record of compromise either....
# There is a privacy/security tradeoff for the user to consider.  If you want
# logging and auditiing, delete the line below
ubuntu1804cis_section4: false
# Below here, is SSH rules, which are not on the standalone server (requires physical
# access with keyboard, mouse and monitor, no remote administration.)
ubuntu1804cis_rule_5_2_1: false
ubuntu1804cis_rule_5_2_2: false
ubuntu1804cis_rule_5_2_3: false
ubuntu1804cis_rule_5_2_4: false
ubuntu1804cis_rule_5_2_5: false
ubuntu1804cis_rule_5_2_6: false
ubuntu1804cis_rule_5_2_7: false
ubuntu1804cis_rule_5_2_8: false
ubuntu1804cis_rule_5_2_9: false
ubuntu1804cis_rule_5_2_10: false
ubuntu1804cis_rule_5_2_11: false
ubuntu1804cis_rule_5_2_12: false
ubuntu1804cis_rule_5_2_13: false
ubuntu1804cis_rule_5_2_14: false
ubuntu1804cis_rule_5_2_15: false
ubuntu1804cis_rule_5_2_16: false
ubuntu1804cis_rule_5_2_17: false
ubuntu1804cis_rule_5_2_18: false
ubuntu1804cis_rule_5_2_19: false
ubuntu1804cis_rule_5_2_20: false
ubuntu1804cis_rule_5_2_21: false
ubuntu1804cis_rule_5_2_22: false
ubuntu1804cis_rule_5_2_23: false

EOF

cd /etc/ansible/

ansible-playbook /etc/ansible/harden.yml

#fix ownership and permission on localhost.key for prosody
chown root:prosody /etc/prosody/certs/localhost.key
chmod g+r /etc/prosody/certs/localhost.key

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
cd ~
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

# Stop and disable system logging - Comment out these lines if you want to keep logging.
#https://stackoverflow.com/questions/17358499/linux-how-to-disable-all-log#32553762
printf "Stopping and Disabling logging..."
systemctl stop rsyslog.service
systemctl disable rsyslog.service


printf "Installation is complete!  However, to apply security patches you need to stop, and then start your instance.\n"
printf "To add more meeting hosts, first change ownership of the add_host.sh file by typing \n"
printf "'sudo chown username addhost.sh', where username is your username.  Then type 'sudo ./add_host'\n"

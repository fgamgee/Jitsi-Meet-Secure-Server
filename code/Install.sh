#!/bin/bash

# Need to add options to script - used https://www.shellscript.sh/tips/getopts/
# One option to specify standalone -s
# One option to specify a branch -b other than 'master'
# add others as we go...

unset BRANCH STANDALONE

BRANCH="master"
STANDALONE=false

while getopts 'sb:' c
do
  case $c in
    s) STANDALONE=true ;;
    b) BRANCH=$OPTARG ;;
  esac
done

# Need to run these after login...  UPDATE to MASTER SOON!
#curl -o Install.sh https://raw.githubusercontent.com/fgamgee/Jitsi-Meet-Secure-Server/master/code/Install.sh
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
# For standalone, disable SSH port, login with a keyboard
if [ "$STANDALONE" = false ]; then
  iptables -A INPUT -p tcp -m tcp --dport 22 -m state --state NEW -j ACCEPT
fi
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
add-apt-repository -y ppa:nginx/stable
apt-get -y update

#add prosody repository and key.
echo 'deb https://packages.prosody.im/debian bionic main' >> /etc/apt/sources.list.d/prosody.list
wget -qO - https://prosody.im/files/prosody-debian-packages.key | apt-key add -
apt-get -y update

#Jitsi-Meet install https://aws.amazon.com/blogs/opensource/getting-started-with-jitsi-an-open-source-web-conferencing-solution/
echo 'deb https://download.jitsi.org stable/' >> /etc/apt/sources.list.d/jitsi-stable.list
wget -qO - https://download.jitsi.org/jitsi-key.gpg.key | apt-key add -
apt-get update
apt-get -y install jitsi-meet

#Let's Encrypt certificate - note, you will see this in the logs (at least nginx), because logging is
# not yet disabled, but I think that is fine.
# This method works fine, but installs Python 2.7, which is EOL.
curl -o /usr/share/jitsi-meet/scripts/install-letsencrypt-cert.sh https://raw.githubusercontent.com/jitsi/jitsi-meet/master/resources/install-letsencrypt-cert.sh
chmod +x /usr/share/jitsi-meet/scripts/install-letsencrypt-cert.sh
/usr/share/jitsi-meet/scripts/install-letsencrypt-cert.sh


#Install Ansible
apt install -y ansible
cd /etc/ansible/
# Get configurations of jitsi
curl -o /etc/ansible/Jitsi_login_req_config.yml https://raw.githubusercontent.com/fgamgee/Jitsi-Meet-Secure-Server/"$BRANCH"/code/Jitsi_login_req_config.yml
curl -o /etc/ansible/Jitsi_TLS_DH_config.yml https://raw.githubusercontent.com/fgamgee/Jitsi-Meet-Secure-Server/"$BRANCH"/code/Jitsi_TLS_DH_config.yml
curl -o /etc/ansible/Jitsi_no_logging.yml https://raw.githubusercontent.com/fgamgee/Jitsi-Meet-Secure-Server/"$BRANCH"/code/Jitsi_no_logging.yml

# For standalone, no SSH
if [ "$STANDALONE" = false ]; then
  curl -o /etc/ansible/Jitsi_SSH_config.yml https://raw.githubusercontent.com/fgamgee/Jitsi-Meet-Secure-Server/"$BRANCH"/code/Jitsi_SSH_config.yml
  ansible-playbook -v Jitsi_SSH_config.yml
fi


# Run configuration for Jitsi
ansible-playbook -v Jitsi_login_req_config.yml
ansible-playbook -v Jitsi_TLS_DH_config.yml

# This is used to disable logging, comment out if you want logging.
ansible-playbook -v Jitsi_no_logging.yml


#Get Ansible playbook for CIS hardening -
# From https://cloudsecuritylife.com/cis-ubuntu-script-to-automate-server-hardening/
sh -c "echo '- src: https://github.com/florianutz/Ubuntu1804-CIS.git' >> /etc/ansible/requirements.yml"

ansible-galaxy install -p roles -r /etc/ansible/requirements.yml
# Make role - don't like this method.  Update needed, maybe move to an ansible file?
cat > /etc/ansible/harden.yml <<EOF
- name: Harden Server
  hosts: localhost
  connection: local
  become: yes

  roles:
    - Ubuntu1804-CIS

EOF

# X Windows is not installed, as can be checked with  dpkg -l xserver-xorg*
# but Ansible xwindows task removes x11 which Jitsi does need
# Needs to have dummy telnet package installed and telnet removed - but Coturn
# has a dependency of telnet (but it is only used for debugging).
# I currently use iptables.
# Rule 4.3 is logrotate, which prosody does not like...  get rid of logging is
# a privacy goal of logrotate is not relevant.
cat > /etc/ansible/roles/Ubuntu1804-CIS/vars/main.yml <<EOF
---
# vars file for Ubuntu1804-CIS
ubuntu1804cis_xwindows_required: true
ubuntu1804cis_telnet_required: true
ubuntu1804cis_firewall: iptables
#logrotate seems to break coturn.  Probably need to add simple-log to turnserver.conf
# to use logrotate (not tested).
ubuntu1804cis_rule_4_3: false
# Below is to disable Auditing and logging, to maintain privacy -
# no record on system if compromised - but no record of compromise either....
# There is a privacy/security tradeoff for the user to consider.  If you want
# logging and auditiing, delete the line below
ubuntu1804cis_section4: false

EOF

# For standalone, no SSH
# note, not as readable, as <<- did not seem to work for me, not sure why...
# https://stackoverflow.com/questions/2500436/how-does-cat-eof-work-in-bash
if [ "$STANDALONE" = true ]; then
cat >> /etc/ansible/roles/Ubuntu1804-CIS/vars/main.yml << EOF
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
fi

cd /etc/ansible/

ansible-playbook /etc/ansible/harden.yml

set +x

#fix ownership and permission on localhost.key for prosody
chown root:prosody /etc/prosody/certs/localhost.key
chmod g+r /etc/prosody/certs/localhost.key



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

user=$(stat -c %U ./Install.sh)
chown $user ./add_host.sh
chmod +x ./add_host.sh

printf "\n"
printf "Let's set up a host and password for meetings.\n"
printf "\n"
./add_host.sh


cat > /etc/ansible/autoshutdown.yml <<EOF
- name: Automatically turn off at specified time.
  hosts: localhost
  become: yes


# Crontab configuration
  tasks:
  - name: Update crontab to auto shutdown
    lineinfile:
      path: /etc/crontab
      regexp: "shutdown"
      line: '{{ minute }} {{ hour }} * * *  root shutdown'
      state: present
EOF


# Make an autoshutdown script that can run daily, so you don't forget to turn
#your AWS instance off.

cat > ~/autoshutdown.sh << EOF
#!/bin/bash

printf "This shell set a job to automatically shutdown daily, so you don't forget and leave \n"
printf "your instance running.  You will need to run it sudo ./auto_shutdown.sh \n"
if [ "$EUID" -ne 0 ]
  then echo "Please run as root, use sudo"
  exit
fi

printf  "your current date and time maybe in UTC.  Here is the time your system thinks it is: \n"
date +"%T"
read -p "Enter the hour (in the same time zone as your system is) you want the shutdown to occur [0-23]: " hour
read -p "Enter the minute you want shutdown to occur, system will give 1 minute warning [0-59]: " minute
if [[ hour -lt  0 || hour -gt 59 ||  minute -lt 0 || minute -gt 59 ]]
  then echo "invalid time given"
  exit
fi
echo "Time shutdown will occur daily \$hour : \$minute"

cd /etc/ansible

ansible-playbook -e "minute=\$minute hour=\$hour" autoshutdown.yml
echo
printf "done \n"

EOF

chown $user ./autoshutdown.sh
chmod +x ./autoshutdown.sh

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


printf "Installation is complete! You can test Jitsi now by starting a meeting.\n"
printf "However, to apply security patches you need to stop, and then start your instance.\n"
printf "\n"
printf "To add more meeting hosts, type 'sudo ./add_host'\n"
printf "\n"
printf "If you are concerned about forgetting to turn off your instance, and running up a big bill, "
printf "at the command line, type: \n"
printf "sudo ./auto_shutdown.sh \n"
printf "and it will set up a cron job that will automatically shut your instance off at the time you specify each day. \n"

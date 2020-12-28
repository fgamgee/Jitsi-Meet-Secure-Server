#!/bin/bash

# Need to add options to script - used https://www.shellscript.sh/tips/getopts/
# One option to specify standalone -s
# One option to specify a branch -b other than 'master'
# add others as we go...

#Updating for Ubuntu2004.

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

# Need to run these after login...  use BRANCH name, instead of master.
#curl -o Install.sh https://raw.githubusercontent.com/fgamgee/Jitsi-Meet-Secure-Server/master/code/Install.sh
#chmod +x Install.sh
#sudo ./Install.sh (argument BRANCH) (argument STANDALONE)

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

#From Quick Install
apt -y install openjdk-8-jdk



#add prosody repository and key.
echo 'deb https://packages.prosody.im/debian focal main' >> /etc/apt/sources.list.d/prosody.list
wget -qO - https://prosody.im/files/prosody-debian-packages.key | apt-key add -
apt-get -y update

#Jitsi-Meet install https://aws.amazon.com/blogs/opensource/getting-started-with-jitsi-an-open-source-web-conferencing-solution/
echo 'deb https://download.jitsi.org stable/' >> /etc/apt/sources.list.d/jitsi-stable.list
wget -qO - https://download.jitsi.org/jitsi-key.gpg.key | apt-key add -
apt-get update
apt-get -y install jitsi-meet

#Let's Encrypt certificate - note, you will see this in the logs (at least nginx), because logging is
# not yet disabled, but I think that is fine.
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

# Use pre-image CIS Level 1 instead of trying to depend on open-source Ansible CIS hardening.



# X Windows is not installed, as can be checked with  dpkg -l xserver-xorg*
# but Ansible xwindows task removes x11 which Jitsi does need
# Needs to have dummy telnet package installed and telnet removed - but Coturn
# has a dependency of telnet (but it is only used for debugging).  Install for now.
apt-get -y install telnet
#

# I currently use iptables.
# Rule 4.3 is logrotate, which prosody does not like...  get rid of logging is
# a privacy goal of logrotate is not relevant.

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

#TBD - turn back on.

#printf "Stopping and Disabling logging..."
#systemctl stop rsyslog.service
#systemctl disable rsyslog.service


printf "Installation is complete! You can test Jitsi now by starting a meeting.\n"
printf "However, to apply security patches you need to stop, and then start your instance.\n"
printf "\n"
printf "To add more meeting hosts, type 'sudo ./add_host'\n"
printf "\n"
printf "If you are concerned about forgetting to turn off your instance, and running up a big bill, \n"
printf "at the command line, type: \n"
printf "sudo ./autoshutdown.sh \n"
printf "and it will set up a cron job that will automatically shut your instance off at the time you specify each day. \n"
printf "\n"
printf "After setting up the chron job, you can uninstall ansible and Python2.7, which will reduce the attack surface by\n"
printf "sudo apt-get remove ansible \n"
printf "sudo apt autoremove \n"

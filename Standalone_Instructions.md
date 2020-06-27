# Hosting a Private/Secure Jitsi-Meet Server on your home/small business network.

This is step by step instructions of how to host a security hardened dedicated Jitsi-Meet server at home. It is specific to a Ubiquity Edge x10 router and DNS registrar AWS (Amazon) Route 53.   However, the main contribution (automated Jitsi Meet and server hardening installation is independent of router and DNS registrar).

Most home networks do not have a static IP, however current practice of network providers seems to be to very infrequently change the IP (months), so it is practical to ignore that limitation and just update your domain name.

You will need a computer to act as a server.  It does not have to be fancy, but should have:
* Intel or AMD cpu (Jitsi-Meet does not work on ARM)
* Ethernet port.
* 8 GB of Memory.
* Keyboard and mouse.
* Monitor.
* USB memory > 16 GB stick to put Ubuntu ISO on (anything else on the stick will be lost).

It does not need a graphics card or wifi (best not to have wifi, but good luck finding a computer without it).  I favor Intel NUCs.   

One issue with using older hardware, is all of the hardware vulnerabilities that have been discovered (and exploits implemented) in the older CPUs, and you should keep your firmware up to date - older hardware firmware updates will likely be unsupported.

## High level overview of the process

1. Set up your Router to port forward to your server.
2. Acquire a Domain Name and assign it an IP.
3. Download recent Ubuntu 18.04 Server and put the ISO on the USB stick.
4. Install Ubuntu with specified Disk Partitions.


### 1. Acquire a Domain Name and assign it your IP.


Assign IP
nslookup domaimname.  (you can do steps 3, but do not do step 4 until your domainname gives the IP address you assigned.)

### 1. Set up Router.

### 3. Download Ubuntu 18.04.

### 4. Install Ubuntu with specified Disk Partitions.

Do a standard Ubuntu install, but when you get to the "Guided storage configuration" step, choose "Custom storage layout".

1. Partition 1 Bootloader partition boot/efi - ESP fat32 size 512 M
2. Partition 2 size 10 G (or larger) Format ext4 Mount /
3. Partition 3 size 10 G (or larger) Format ext4 Mount /home
4. Partition 4 size 5 G (or larger) Format ext4 Mount /usr
5. Partition 5 size 2 G (or larger) Format ext4 Mount /var
6. Partition 6 size 2 G (or larger) Format ext4 Mount /var/tmp
7. Partition 7 size 2 G (or larger) Format ext4 Mount /var/log
8. Partition 8 size 2 G (or larger) Format ext4 Mount /var/log/audit
9. Partition 9 size 64 G (or larger) Format SWAP

Do not install OpenSSH, do not install additional options.

After the install, take your USB stick out and reboot.  On reboot, it will say no authorized SSH keys....  hit return, and enter your username and passwords.

### 5. Install and automatically harden Jitsi Meet

Type out the following commands one at a time (hit Enter and wait for each one to finish before running the next one)
```
curl -o Install.sh https://raw.githubusercontent.com/fgamgee/Jitsi-Meet-Secure-Server/master/code/Install_standalone.sh
chmod +x Install.sh
script out.txt
sudo ./Install.sh
```
### 12. Answer a few prompts.
_If you make a mistake anywhere, it's very quick and easy to start over by setting up a new instance. See below for how to set up a new instance._

Once you start running the last command, a lot of text will start scrolling past on the screen. You will get a blue or pink screen – with a red **\<Yes\>** - press enter – **TWICE**.

More text will scroll – occasionally it will stop scrolling for a minute – be patient. If everything is going well you will get another bright pink or blue screen. **Type in your domain name and press enter.**

Almost immediately, another pink or blue screen will say **"Generate a new self-signed certificate …."** Press enter. We will change this to a real certificate very soon.

More text…. Be patient. Next you will get a prompt:
```
Enter your email and press [ENTER]:
```
Enter the email address associated with your domain name and press enter. This is sent to Let's Encrypt to obtain a security certificate.

Then lots more text. You may see a couple of  ```[WARNING]``` messages but that is normal. The Init AIDE task will also take several minutes, so be patient if it appears to hang.
Eventually you will see the message:
```
Username for host of meeting:
```
You need to enter a username for someone to host a meeting.  Type the username and press ENTER.  Then you will see:

```
Password:
```
Type in a password for the host to use when starting meetings and press ENTER.  *Note, the password will *NOT* appear on the screen as you type.*

Installation is complete!

End Script.

```exit```

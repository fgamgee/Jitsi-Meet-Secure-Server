# Hosting a Private/Secure Jitsi-Meet Server on your home/small business network.

This is step by step instructions of how to host a security hardened dedicated Jitsi-Meet server at home or small office (SOHO).  The number of participants is primarily limited by your bandwidth.  With 75 Mbs network bandwidth, you should be able to have 8-12 participants.  There is lots of discussion on the Jitsi Community forum about performance, please go there for information and questions about performance.

These instructions use the specific example of a Ubiquity Edge x10 router and DNS registrar AWS (Amazon) Route 53.   However, the automated Jitsi Meet and server hardening installation is independent of router and DNS registrar.

Most home networks do not have a static IP, however current practice of network providers seems to be to very infrequently change the IP (months), so it is practical to ignore that limitation and just update your domain name when your IP changes.

You will need a computer to act as a server.  It does not have to be fancy, but should have:
* Intel or AMD cpu (Jitsi-Meet does not work on ARM)
* Ethernet port.
* Minimum of 8 GB of Memory ()
* Keyboard and mouse.
* Monitor.
* USB memory > 16 GB stick to put Ubuntu ISO on (anything else on the stick will be lost).
* Minimum upstream/downstream bandwidth of 75 Mbs.

It does not need a graphics card or wifi (best not to have wifi, but good luck finding a computer without it).  I favor Intel NUCs.   

One issue with using older hardware, is all of the hardware vulnerabilities that have been discovered (and exploits implemented) in the older CPUs, and you should keep your router and server firmware up to date - for older hardware, firmware updates will likely be unsupported.

## High level overview of the process

1. Set up your Router to port forward to your server.
2. Acquire a Domain Name and assign it the IP of  your router.
3. Download recent Ubuntu 18.04 Server and put the ISO on the USB stick.
4. Install Ubuntu with specified Disk Partitions.
5. Install and automatically harden Jitsi Meet.
6. Reboot to update with security patches and test your setup.

### 1. Set up Router
<!--- change master to branchname, or vis-a-versus when branching/merging -->
Follow this [link](https://github.com/fgamgee/Jitsi-Meet-Secure-Server/blob/master/Documents/ubiquity_edge_setup.md) for instructions for [Ubuiquity Edge Router](https://github.com/fgamgee/Jitsi-Meet-Secure-Server/blob/master/Documents/ubiquity_edge_setup.md).

### 2. Acquire a Domain Name and assign it your IP.
<!--- change master to branchname, or vis-a-versus when branching/merging -->
Follow this [link](https://github.com/fgamgee/Jitsi-Meet-Secure-Server/blob/master/Documents/AWS_Domain_name.md) for instructions for [AWS Registrar and DNS setup](https://github.com/fgamgee/Jitsi-Meet-Secure-Server/blob/master/Documents/AWS_Domain_name.md).

### 3. Download Ubuntu 18.04.

You need to make a USB stick with the software.  Follow the links below, and in step 2, be sure to download [Ubuntu 18.04 LTS Server](https://releases.ubuntu.com/18.04/):

* [Windows instructions](https://ubuntu.com/tutorials/tutorial-create-a-usb-stick-on-windows#1-overview)
* [Mac instructions](https://ubuntu.com/tutorials/create-a-usb-stick-on-macos#1-overview)
* [Ubuntu instructions](https://ubuntu.com/tutorials/create-a-usb-stick-on-ubuntu#1-overview)


### 4. Install Ubuntu with specified Disk Partitions.

Do a standard Ubuntu Server install (see [Instructions](https://ubuntu.com/tutorials/install-ubuntu-server#1-overview)), but when you get to "Guided storage configuration" step 8, choose "Custom storage layout".  This is done for the [CIS Level 1&2 benchmark](https://www.cisecurity.org/benchmark/ubuntu_linux/) (hardening guidelines).  They provide justification in their benchmark for how this makes your server more secure.

Under "Available devices choose to add GPT Partition" to add the following partitions.

1. Partition 1 size 20 G (or larger) Format ext4 Mount /
2. Partition 2 Bootloader partition boot/efi - ESP fat32 size 512 M (automatically created)
3. Partition 3 size 5 G (or larger) Format ext4 Mount /home
4. Partition 4 size 10 G (or larger) Format ext4 Mount /usr
5. Partition 5 size 5 G (or larger) Format ext4 Mount /var
6. Partition 6 size 2 G (or larger) Format ext4 Mount /var/tmp (for Mount: choose "Other", then type /var/tmp)
7. Partition 7 size 2 G (or larger) Format ext4 Mount /var/log (for Mount: choose "Other", then type /var/log)
8. Partition 8 size 2 G (or larger) Format ext4 Mount /var/log/audit (for Mount: choose "Other", then type /var/log/audit)
9. Partition 9 size 64 G (or larger) Format SWAP

Then, choose Done.

Do not install OpenSSH, do not install additional options, go ahead and apply security updates.

After the install, it will apply security updates. When it is done, it will give you the option to Reboot. Reboot, and take your USB stick out while it is briefly shut down.  On reboot, it will say no authorized SSH keys....  hit return, and enter your username and passwords.

### 5. Install and automatically harden Jitsi Meet

<!--- change master to branchname if using development branch -->
Type out the following commands one at a time (hit Enter and wait for each one to finish before running the next one)
```
curl -o Install.sh https://raw.githubusercontent.com/fgamgee/Jitsi-Meet-Secure-Server/master/code/Install_standalone.sh
chmod +x Install.sh
script out.txt
sudo ./Install.sh
```
It will ask you for your password, type it in and hit **Enter**.

Once you start running the last command, a lot of text will start scrolling past on the screen. You will get a blue or pink screen – with a red **\<Yes\>** - press enter – **TWICE**.


Some more text, then you will get the message:
```
**Development releases of Ubuntu are not officially supported by this PPA, and uploads for those will not be available until Beta releases for those versions**
 More info: https://launchpad.net/~nginx/+archive/ubuntu/stable
Press [ENTER] to continue or Ctrl-c to cancel adding it.
```
Press **Enter**


More text will scroll – occasionally it will stop scrolling for a minute – be patient. If everything is going well you will get another bright pink or blue screen. **Type in your domain name and press enter.**

Almost immediately, another pink or blue screen will say **"Generate a new self-signed certificate …."** Press **Enter**. We will change this to a real certificate very soon.

More text…. Be patient. Next you will get a prompt:
```
Enter your email and press [ENTER]:
```
Enter the email address associated with your domain name and press **Enter**. This is sent to Let's Encrypt to obtain a security certificate.

Then lots more text. You will see a couple of  ```[WARNING]``` messages but that is normal. The Init AIDE task will also take several minutes, so be patient if it appears to hang.
Eventually you will see the message:
```
Username for host of meeting:
```
You need to enter a username for someone to host a meeting.  Type the username and press ENTER.  Then you will see:

```
Password:
```
Type in a password for the host to use when starting meetings and press **Enter**.  *Note, the password will *NOT* appear on the screen as you type.*

Installation is complete!

End Script.

```
exit
```

If you want to follow the details of the install (all the text that went by, which may be helpful if for some reason the installation did not work), you can look at it by typing:

```
cat out.txt | more
```

To add more meeting hosts, first change ownership of the add_host.sh file by typing

```
sudo chown username addhost.sh`
```
where username is your username.  Then type
```
sudo ./add_host
```


### 6. Reboot to update with security patches and test your setup.

```
sudo reboot
```

After your server has rebooted, it should be ready to host Jitsi Meet video conferences.  You do not even need to login to the server for it to work, just turn it on and give it time to come up.

More information on using Jitsi is here: https://blogs.systweak.com/how-to-use-jitsi-meet/ just substitute your domainname instead of meet.jit.si in that blog.  

You can use Jitsi-Meet whenever your server is on.  If you do not it up all the time, it is more secure (and green) to turn your server off when you are not hosting video conferences.  Hardware that is powered off is very secure!  Do reboot every couple of weeks (or more often) to make sure you get security updates applied.

You do not need to keep the keyboard, mouse and monitor connected to it, as you only occasionally need to log into it and check that security updates are being applied (which should be automatic on reboot).

# Jitsi-Meet-Secure-Server
Project for newbies (NOOBs) so they can have a private and secure [Jitsi-Meet](https://jitsi.org/jitsi-meet/) server.  It is specifically for those who do not know how to host a secure webserver, but need a private videoconferencing solution.  The Jitsi development team provides a [quick install](https://jitsi.github.io/handbook/docs/devops-guide/devops-guide-quickstart), but the user is responsible for securing the server.  This project automates the process of securing the server including hardening using [CIS benchmarks](https://www.cisecurity.org/cis-benchmarks/), [CVE](https://en.wikipedia.org/wiki/Common_Vulnerabilities_and_Exposures) elimination or mitigations, secure defaults, and providing for meeting host authorization and controls.

## Introduction
This project provides an open source solutions based on Jitsi-Meet to meet the needs of individuals or small organizations intended for cloud deployment.
(The standalone version is not currently supported.)

For a complete description, see the documents folder, in particular, [Private_Secure_Jitsi_project](/Documents/Private_Secure_Jitsi_project.pdf).
**Note**, that the Security Evaluation of Jitsi and meet.jit.si in [Private_Secure_Jitsi_project](/Documents/Private_Secure_Jitsi_project.pdf) is dated - I waited until the Jitsi development team updated the Jitsi install before posting the document.  The default Jitsi is improved significantly from what is reported in the [Private_Secure_Jitsi_project](/Documents/Private_Secure_Jitsi_project.pdf).  However, using this repository will get you all the improvements of the new Jitsi stable install and more.

## Invitation to use and help.

- For a cloud solution, use [Install_Instructions](/Install_Instructions.md)

Let me know by using "Issues" if you have trouble, and I will try to help.  If you use this guide successfully, please also put something in the Issues so I know other people can actually use it - and you are welcome to include suggestions for improvements.

Contributors are welcome.  There are lots of things that could be added or cleaned up.  I will try to keep the Next up section for improvements I know are needed.

**NEW**
I have moved this to Ubuntu 20.04LTS, from Ubuntu 18.04LTS.  In doing so, I decided NOT to harden with an open source CIS (I did not find one sufficiently stable at the time) and I am instead using a CIS L1 image on AWS.  Also, as of the end of 2020, the standalone (non-cloud) version is untested on Ubuntu 20.04, and installation instructions have been removed (see the Ubuntu 18 branch if you want to do a standalone version)

## Pen Testing

- Pen testing is welcome!  See the threat model before you begin. Use a set of the instructions (your choice, but the cloud solution is probably easiest) to set up your target to attack.  I am sure there could be significant improvements - so please suggest in Issues or better yet, pull requests with mitigations!  I welcome community involvement.

## Next up

- Update Install Instructions to move some of the AWS specific things into links, and focus more on this automated solution and less on cloud/domain name things.


## Acknowledgements
I had a lot of help from the 8x8 Jitsi development team.

## License:
Apache 2.0

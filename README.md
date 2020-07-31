# Jitsi-Meet-Secure-Server
Project for newbies (NOOBs) so they can have a private and secure Jitsi-Meet server.  It is specifically for those who do not know how to host a secure webserver, but need a private videoconferencing solution.  The Jitsi development team provides a quick install, but the user is responsible for securing the server.  This project automates that process.

## Introduction
This project provides two complete, open source solutions based on Jitsi-Meet to meet the needs of individuals or small organizations. One is intended for cloud deployment and one intended as a dedicated server running in a SOHO (Small Office/Home Office) environment.

For a complete description, see the documents folder, in particular, [Private_Secure_Jitsi_project](/Documents/Private_Secure_Jitsi_project.pdf).
**Note**, that the Security Evaluation of Jitsi and meet.jit.si in [Private_Secure_Jitsi_project](/Documents/Private_Secure_Jitsi_project.pdf) is dated - I waited until the Jitsi development team updated the Jitsi install before posting the document.  The default Jitsi is improved significantly from what is reported in the [Private_Secure_Jitsi_project](/Documents/Private_Secure_Jitsi_project.pdf).  However, using this repository will get you all the improvements of the new Jitsi stable install and more.

## Invitation to use and help.

- For a cloud solution, use Install_Instructions
- To run a server in your SOHO environment, use Standalone_Instructions

Let me know by using "Issues" if you have trouble, and I will try to help.  If you use this guide successfully, please also put something in the Issues so I know other people can actually use it - and you are welcome to include suggestions for improvements.

Contributors are welcome.  There are lots of things that could be added or cleaned up.  I will try to keep the Next up section for improvements I know are needed.

## Pen Testing

- Pen testing is welcome!  See threat model before you begin. Use a set of the instructions (your choice, but the cloud solution is probably easiest).  I am sure there could be significant improvements - so please suggest in Issues or better yet, pull requests with mitigations!  I welcome community involvement.

## Next up

- Let's Encrypt solution provided with Jitsi Meet installs Python 2.7, which is unsupported EOL.  Need to have a solution that uses Python3 - it is possible according to Let's Encrypt website, but need to automate.
- Combine the two installs into one install with command line options for easier maintenance.
- Give option of generation of 4096 bit DH key (instead of 2048 bit) on command line of installs.

License:
Apache 2.0

# Design Document 1.0
##### Rev 0.1 - First draft May 27, 2020.
##### Rev 0.2 - Update Testing and Maintenance. May 28, 2020.
##### Rev 1.0 - Begin Implementation based on this, update as needed. May 29, 2020

**Author**: Kevin E. Wilson, PhD

## 1 Design Considerations

### 1.1 Assumptions

This document will provide the design for enabling the setting up a private and secure dedicated Jitsi Meet server for a video conference for a few people, either in the cloud or stand-alone, appropriate for utilization by a small organization or individual. The project will run in the open source Jitsi community on Github and invite comments and contributions from the open source community. Secondarily to privacy and security, ease of use will also be a design goal.

The user is assumed to be a technically savvy individual with some familiarity with linux, but lacking any experience with the required individual components (setting up a server, firewalls, DNS domain registration, etc.).

The design may utilize code from various open source repositories on Github provided by individuals. The continued availability and maintenance of this code cannot be guaranteed by this author.

### 1.2 Constraints

For the cloud solution, cost will be the primary constraint, but it is expected that cost will be very modest, less than $300 for a year.

In the stand-alone environment, network bandwidth is likely to limit the number of participants.  Hardware and network bandwidth utilization will be benchmarked for up to a dozen participants.  Cost will be much higher than the cloud solution if new hardware is required and/or network bandwidth must be purchased. If existing hardware can be repurposed and network bandwidth cost is freely available, the marginal cost may be zero.

The install must be idempotent.

### 1.3 System Environment

This project will be developed for an Ubuntu 18.04 server.  Both a cloud solution (AWS or similar) and a stand-alone solution using an Intel NUC 10 i7 behind an Ubiquiti Edge router will be supported.


## 2 Architectural Design

### 2.1 Components

A Bash or similar script will be utilized to run the installation process. The firewall will be configured and activated by either bash or Ansible (TBD). The script will install and utilize the Ansible (https://www.ansible.com/) package.  Ansible is a popular open source package for the configuration and maintenance of servers and is by design idempotent.  Ansible will be used to harden the software using recommendations from the CIS Benchmark (https://www.cisecurity.org/cis-hardened-images/), however not all recommendations will be used.  In particular, logging will be disabled to increase privacy, others may not be compatible with Jitsi Meet. Ansible will also be used to install and configure Jitsi Meet and related components, Prosody, Turn, and Jicofo. Let's Encrypt certificate will be automated by the bash script.

### 2.2 Component Diagram

![ui component](./diagram/Fig1.png)


## 3 User Interface Design

Detailed instructions will be provided.

The user interface will be the command line.  Automation will be used to minimize the commands and the complexity of those commands that the user will need to enter.

Installation will report on progress and success or failure of each step, with an overall report of number of successful steps, steps skipped, and steps that failed.

The installation will be idempotent, so that the user will not cause issues if he performs the installation multiple times.

## 4 Testing
Instructions will be provided for the user to check for misconfigurations and vulnerabilities of the server using automated test tools such as Qualys SSL Labs (https://www.ssllabs.com/ssltest/) and Openscap (https://www.open-scap.org/), and also what the expected results are from a successful installation.

## 5 Maintenance
Process for maintaining the Jitsi-Meet server will be provided.  Automation of maintenance will be preferred, such as automatic updates applying security patches.

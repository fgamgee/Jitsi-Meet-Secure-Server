# Design Document 1.0
##### Rev 0.1 - First draft May 27, 2020.
##### Rev 0.2 - Update Testing and Maintenance. May 28, 2020.
##### Rev 1.0 - Begin Implementation based on this, update as needed. May 29, 2020
##### Rev 2.0 - At Implementation based on Tag v0.11 on master. July 10, 2020


## 1 Design Considerations

### 1.1 Assumptions

This document will provide the design for enabling the setting up a private and secure dedicated Jitsi Meet server for a video conference for a few people, either in the cloud or stand-alone, appropriate for utilization by a small organization or individual. The project will run in a public Github repository and invite comments and contributions from the open source community. Secondarily to privacy and security, ease of use will also be a design goal.

The user is assumed to be a technically savvy individual with some familiarity with linux, but lacking any experience with the required individual components (setting up a server, firewalls, DNS domain registration, etc.).

The design may utilize code from various open source repositories on Github provided by individuals. The continued availability and maintenance of this code cannot be guaranteed by this project.

### 1.2 Constraints

For the cloud solution, cost will be the primary constraint, but it is expected that cost will be very modest, approximately $50 for a year.

In the stand-alone environment, network bandwidth is likely to limit the number of participants.  Hardware and network bandwidth utilization will be benchmarked for up to a dozen participants.  Cost will be much higher than the cloud solution if new hardware is required and/or network bandwidth must be purchased. If existing hardware can be repurposed and network bandwidth cost is freely available (e.g. already purchased), the marginal cost may be zero.

### 1.3 System Environment

This project will be developed for an Ubuntu 18.04 server.  Both a cloud solution (AWS or similar) and a stand-alone solution using an Intel NUC 10 i7 behind an Ubiquiti Edge router will be supported.

The automation is independent of cloud provider and hardware.  However, the step by step instructions will need to be modified if you choose a different cloud provider or router.

## 2 Architectural Design

### 2.1 Components

A Bash script will be utilized to run the installation process. The firewall will be configured and activated. The script will install Jitsi Meet, Let's Encrypt and Ansible (https://www.ansible.com/), with all needed package dependencies.  Ansible is a popular open source package for the configuration and maintenance of servers.  Ansible will be used to harden the software using recommendations from the CIS Benchmark (https://www.cisecurity.org/cis-hardened-images/), however not all recommendations of CIS will be used.  In particular, logging will be disabled to increase privacy, and Jitsi Meet uses coturn which has telnet as a package dependence. Ansible will be used to configure Jitsi Meet and related components, nginx, prosody, coturn, etc.

### 2.2 Component Diagram

![ui component](../diagrams/Fig1.png)

## 3 User Interface Design

Detailed instructions will be provided.

The user interface will be the command line.  Automation will be used to minimize the commands and the complexity of those commands that the user will need to enter.

Installation will report on progress and success or failure of each step, with an overall report of number of successful steps, steps skipped, and steps that failed.

The installation will be idempotent, so that the user will not cause issues if he performs the installation multiple times.

## 4 Testing
Instructions will be provided for the user to check for misconfigurations and vulnerabilities of the server using automated test tools such as [Mozilla Observatory](https://observatory.mozilla.org/analyze/) Qualys SSL Labs (https://www.ssllabs.com/ssltest/), [SecurityHeaders.com](https://securityheaders.com), [Immuniweb](https://www.immuniweb.com/), [Greenbone Community Edition, formerly OpenVAS](https://www.greenbone.net/en/community-edition/) and also what the expected results are from a successful installation.  CVE's will be examined manually for packages as well (particularly packages that are exposed, such as coturn, prosody, etc.)

## 5 Maintenance
Automatic security updates, with appropriate repositories will be enabled.

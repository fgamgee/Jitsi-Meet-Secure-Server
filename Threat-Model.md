These guidelines are for private and secure video-conferencing and are appropriate for individuals and non-profit organizations that do not possess the resources required to hire an IT professional or cybersecurity expert.
Complete instructions will be provided to host your own Jitsi-Meet server.  Before proceeding, determine if you really need to deploy your own Jitsi-Meet server by reading https://jitsi.org/security/

Reasons why you may need to deploy your own server:
1. You need moderator controls (mute, kicking someone out of the meeting) to be restricted to the host.  *E.g.* you are a teacher running a class.  These can be configured to your preference if you host your own server.
2. You would prefer not to trust or depend upon the security of a third party provider or agree to their Terms of Service and Privacy Policy, even a fine upstanding one such as "8x8" which hosts https://meet.jit.si for free use.
3. You want to be in contol of your own data.  Corporations can be acquired, go bankrupt, change their privacy policies and terms of service, etc. and you wish to be independent.  You stronly value your right to privacy "the right to be let alone" ("The Right to Privacy" published in the *Harvard Law Review*, 1890).
4. You want no logs kept of the meetings.
5. Your organization has policies that prohibit you from trusting third-parties that you do not have an established relationship with.

These guidelines are designed to protect against mass surveillance from both corporations and criminals.  They are designed to protect the users of the video-conferencing from:
1. Their personal information being collected by a corporation, and thus subject to subsequent security breaches with leakage of their information to criminals and others.
2. The video-conference being hijacked by hackers who want to disrupt or spy on the meeting.
3. Someone other than the host muting particpants or kicking them out of the meeting.
4. Tracking analytics being collected on the particpants in the conference.
5. Requiring the users to agree to share their information with a third party, such as the video-conferencing provider.
6. Requiring the users to download software which may contain vulnerabilities or otherwise compromise their computer to participate in the conference.

The guidelines are not appropriate for protection from targeted attacks by nation-states.  They provide a level of security for protection against organized crime, but again may not be sufficient for targeted attacks from a well-resoured attacker who can gain physical access to the server or comporomise one of the particpants computers.

The Threat model follows the STRIDE Methodology (https://en.wikipedia.org/wiki/STRIDE_(security)), is a Work in Progress (WIP) and limited in scope to the hosting of a Jitsi-Meet Server.

Threat | Mitigation (WIP)
-------|----------
Spoofing | Password Authentication required to start a meeting.  Unique URL and password can be required to join the meeting.  Let's Encrypt certificate for domain name.
Tampering| CIS Benchmark Level 1 on server.  Firewall. SSH for server management. Scheduled use to automatically turn server off when not in use. Update management.
Repudiation (denial of the truth or validity of something) | None contemptplated.  Conflicts with privacy goal.
Information Disclosure | Encryption using WebRTC.  No logs kept on the server.
Denial of Service | Require Authentication to start a meeting, prevents adversary from starting multiple meetings.  Restrictive firewall rules.  Protection very rudimentary.
Elevation of Privilege |  CIS Benchmark Level 1 on server which enables AppArmor.

Known issues.
* Compromised host of one of the participants.  This will result in Information Disclosure.  Outside of scope.
* Root access from server provider gains access to meeting in unencrypted form resulting in Information Disclosure (remediation under development by Jitsi community, see https://jitsi.org/blog/e2ee/).
* DOS and DDOS attacks.  Outside of scope.
* Man-in-the-middle-attacks.  This is a difficult attack to perform, needs to be targeted and is typically executed by a strong adversary. Outside of scope.

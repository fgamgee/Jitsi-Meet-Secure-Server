## Who is protected? ##

This project is for private and secure videoconferencing and will be appropriate for individuals and non-profit organizations that do not possess the resources required to hire an IT professional or cybersecurity expert.
Complete instructions will be provided to host your own Jitsi-Meet server.  Before proceeding, determine if you really need to deploy your own Jitsi-Meet server by reading https://jitsi.org/security/

Reasons why you may need to deploy your own server:  
1. You need moderator controls (mute, kicking someone out of the meeting) to be restricted to the host.  *E.g.* you are a teacher running a class.  These can be configured to your preference if you host your own server.
2. You would prefer not to trust or depend upon the security of a third-party provider or agree to their Terms of Service and Privacy Policy, even a fine upstanding one such as "8x8" which hosts https://meet.jit.si for free use.
3. You want to be in control of your own data.  Corporations can be acquired, go bankrupt, change their privacy policies and terms of service, etc. and you wish to be independent.  You strongly value your right to privacy "the right to be let alone" ("The Right to Privacy" published in the *Harvard Law Review*, 1890).
4. You want no logs kept of the meetings.
5. Your organization has policies that prohibit you from trusting third parties that you do not have an established relationship with.

## Threat Model ##

This project is designed to protect against mass surveillance from both corporations and criminals.  It is designed to protect the users of the videoconferencing from:
1. Their personal information being collected by a corporation, and thus subject to subsequent security breaches with leakage of their information to criminals and others.
2. The videoconference being hijacked by hackers who want to disrupt or spy on the meeting.
3. Someone other than the host muting participants or kicking them out of the meeting.
4. Tracking analytics being collected on the participants in the conference.
5. Requiring the users to agree to share their information with a third party, such as the videoconferencing provider.
6. Requiring the users to download software which may contain vulnerabilities or otherwise compromise their computer to participate in the conference.

The project will not be appropriate for protection from targeted attacks by nation-states.  It provides a level of security for protection against organized crime, but again may not be sufficient for targeted attacks from a well-resourced attacker who can gain physical access to the server or compromise one of the participants computers.

All participants of the meeting are assumed to be trusted, as well as by extension the device they use to connect to the meeting or devices that are present with them (e.g. digital assistants or phones) during the meeting.  There is no protection that would keep a participant from surreptitiously recording the meeting using their phone or other device, nor is there significant protection from a participant actively disrupting the meeting - though host controls (allowing the muting of participants and kicking them out of the meeting) can provide modest protection, appropriate for a classroom.

The Threat model follows the STRIDE Methodology (https://en.wikipedia.org/wiki/STRIDE_(security)), is a Work in Progress (WIP) and limited in scope to the hosting of a Jitsi-Meet Server.

Threat | Mitigation (WIP)
-------|----------
Spoofing | Password Authentication required to start a meeting.  Unique URL and password can be required to join the meeting.  Let's Encrypt certificate for domain name.
Tampering| CIS Benchmark Level 1 on server.  Firewall. SSH for server management. Scheduled use to automatically turn server off when not in use. Update management.
Repudiation (denial of the truth or validity of something) | Can conflict with privacy goal in general case.  However, meetings can require passwords which could be sent securely to participants with asymmetric key encryption.
Information Disclosure | Encryption using WebRTC. Configured to require TLSv1.2 or 1.3 with secure ciphers and use secure DH key exchange. No logs kept on the server.
Denial of Service | Require Authentication to start a meeting, prevents adversary from starting multiple meetings.  Restrictive firewall rules.  Protection very rudimentary.
Elevation of Privilege |  CIS Benchmark Level 1 on server which enables AppArmor.

Known issues:  
* Compromised host of one of the participants.  This will result in Information Disclosure.  Outside of scope.
* Root access from server provider gains access to meeting in unencrypted form resulting in Information Disclosure (remediation under development by Jitsi community, see https://jitsi.org/blog/e2ee/).
* DOS and DDOS attacks.  Outside of scope.
* Man-in-the-middle-attacks.  This is a difficult attack to perform, needs to be targeted and is typically executed by a strong adversary. Outside of scope.
* VOIP has vulnerabilities based on natural speech, and users should be aware of attacks such as described by Andrew White *et.al. Phonotactic Reconstruction of Encrypted VoIP conversations: Hookt on fon-iks.* Proceedings of IEEE Symposium on Security and Privacy, May, 2011. (available https://www.cs.unc.edu/~fabian/papers/foniks-oak11.pdf)
* WebRTC uses an “audio level” header extension (see https://tools.ietf.org/html/rfc6464) in each audio packet, that is unencrypted and provides more information than the packet size alone. This can be disabled, but this will disable the ability of the server to detect the active speaker and automatically switch the to it (from Boris Grozev).
  * As pointed out by the link, this audio level header extension can be used by a participant for a DOS attack, however this is outside of scope in that participants in a conference must be trusted.  Some mitigation is provided in that the host can kick someone out of a meeting and then inform the remaining participants of a new meeting link or password and restart the meeting.
  * An additional concern is that audio levels are visible on a
   packet-by-packet basis to an attacker passively observing the audio
   stream.  As discussed in [https://tools.ietf.org/html/rfc6562], an attacker might be
   able to infer information about the conversation, possibly with
   phoneme-level resolution.  In scenarios where this is a concern,
   additional mechanisms MUST be used to protect the confidentiality of
   the header extension.

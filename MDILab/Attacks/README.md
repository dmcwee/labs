# MDI Lab Attack Scenarios

* [Account Over Permissions](./AccountOverPermissions.md)
* [DNS Zone Transfer](./DnsZoneTransfer.md)
* [Honey Token Account](./HoneytokenAccount.md)
* [LDAP Recon](./LdapRecon.md)
* [Net Session Enumeration](./NetSessionEnumeration.md)
* [Network Mapping Recon](./NetworkMappingRecon.md)
* [Remote Code Execution](./RemoteCodeExecution.md)
* [Suspicious Account Addition](./SuspiciousAccountAddition.md)

## Scenarios

### Account Over Permissions

This attack simulation demonstrates a privilege escalation technique where an attacker creates or leverages an existing domain account and adds it to multiple highly privileged groups simultaneously. Unlike a targeted addition to a single group, this script escalates an account across several sensitive groups at once — including Domain Admins, Enterprise Admins, Schema Admins, Account Operators, and Backup Operators — mimicking an aggressive privilege escalation or insider threat scenario.

Microsoft Defender for Identity (MDI) monitors for suspicious modifications to sensitive groups and generates alerts when unusual or bulk additions are detected.

### DNS Zone Transfer

DNS Zone Transfer is a reconnaissance technique used by attackers to obtain a complete copy of DNS records for a domain. By performing zone transfer requests (AXFR) or exhaustively querying DNS record types, attackers can map the network infrastructure, discover internal hostnames, identify servers, and locate potential targets for further exploitation.

Microsoft Defender for Identity (MDI) detects suspicious DNS activity including zone transfer attempts originating from non-DNS servers and excessive DNS query volumes, which are strong indicators of network reconnaissance.

### Honey Token Account

Honeytoken accounts are decoy accounts strategically placed in an environment to act as early warning indicators of malicious activity. These accounts are intentionally made to appear valuable (e.g., administrative accounts with enticing names) but are never used for legitimate purposes. Any authentication attempt, LDAP query, or interaction with a honeytoken account is immediately suspicious and indicates potential reconnaissance or credential theft activity.

Microsoft Defender for Identity (MDI) can monitor tagged honeytoken accounts and generate alerts when any activity is detected, providing high-fidelity detection with minimal false positives.

### LDAP RECON

Attackers will use LDAP reconnaisance techniquest to discover valid users accounts and other objects within active directory. This information helps adversaries identify additional account and computer targets to further identify their foothold in the environment.

This simulation also includes searching and enumerating SPN values in the domain.

### Net Session Enumeration (SMB Session Enumeration)

Net Session Enumeration is a reconnaissance technique used by attackers to discover active SMB sessions on remote computers within a network. By calling the Windows `NetSessionEnum` API, attackers can identify which users are currently logged into which machines, enabling them to locate high-value targets such as Domain Admins with active sessions and plan lateral movement accordingly.

This technique is commonly used during the discovery phase of an attack. Users and computers access the SYSVOL share to retrieve Group Policy Objects (GPOs), which means domain controllers typically have sessions from many users. Attackers exploit this to map user-to-machine relationships across the network.

Microsoft Defender for Identity (MDI) detects suspicious SMB session enumeration targeting monitored hosts and generates alerts for this reconnaissance activity.

### Network Mapping Recon

This reconnaissance is used by attackers to map your network structure and target interesting computers for later steps in their attack.

There are several query types in the DNS protocol. This Defender for Identity security alert detects suspicious requests, either requests using an AXFR (transfer) originating from non-DNS servers, or those using an excessive number of requests.

### Remote Code Execution

This attack simulation demonstrates a lateral movement technique where an attacker uses PowerShell Remoting (`Invoke-Command`) to execute code on a remote machine. The script connects to a target computer and writes an entry into the Windows Application Event Log, simulating a remote code execution scenario.

PowerShell Remoting is a legitimate administrative feature, but it is frequently abused by attackers for lateral movement after gaining initial access. Microsoft Defender for Identity (MDI) and Microsoft Defender for Endpoint (MDE) can detect suspicious remote execution patterns targeting monitored systems.

### Suspicious Account Addition

This attack simulation demonstrates a common persistence technique where an attacker adds a compromised or newly created user account to sensitive groups such as Domain Admins. Microsoft Defender for Identity (MDI) monitors for suspicious modifications to sensitive groups and generates alerts when unusual additions are detected.

This type of attack is commonly used after an attacker gains initial access to establish persistence and escalate privileges within an Active Directory environment.

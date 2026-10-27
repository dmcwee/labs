# MDI Lab Attack Scenarios

## Deployment context

These instructions match the standalone [MDI deployment](../README.md) and
its [Bicep entrypoint](../modules/mdilab.bicep). The default first forest is
`mayor.mcweeinc.com` (`subDomain1`, NetBIOS `mayor` / `netbiosName1`); the second
is `tech.mcweeinc.com` (`subDomain2`, NetBIOS `tech` / `netbiosName2`). They are
independent forests: **no child-domain relationship or trust is created**.

Examples target the first forest unless stated otherwise. For the second,
change the controller, DNS configuration, domain, and account prefix together.
Use your parameter values if you overrode the defaults. The
[unified Defender deployment](../../Defender/README.md) instead uses `LabAd`
and `LabSubAd`; do not assume the standalone MDI hostnames or IPs apply there.
Check [published/source differences](../../docs/deployment-alignment.md) and
actual provisioning before running a scenario.

## Accounts and sign-in

The deployment requires `username` and `password`; **there is no default
administrator username**. Initially sign in to a member Windows VM using
`.\<deployment-username>` and the password you supplied. Replace that placeholder
with your actual deployment value; it is not a scenario account.

Azure deployment and Defender portal access use your own authorized tenant
account. The VM/domain accounts below do not create cloud identities or grant
tenant roles.

After each controller is promoted, restarted, and signed in, the staged
[DcHydrate.ps1](../../Common/DSC/DcHydrate.ps1) creates these users in that
forest's `LabUsers` OU:

| Display name | Account name | Additional groups assigned by hydration |
| --- | --- | --- |
| John Smith | `jsmith` | None. |
| Jeff Leatherman | `jeffl` | None. |
| Ron HelpDesk | `ronhd` | Helpdesk. |
| John Admin | `johna` | Domain Admins. |
| Samira Abbasi | `samiraa` | Domain Admins. |
| Admin Backup | `admin_bak` | Remote IT Admin; Admin Backup. |

With defaults, standard-user examples use `mayor\jsmith`
(`jsmith@mayor.mcweeinc.com`) and administrative steps use `mayor\johna`
(`johna@mayor.mcweeinc.com`). The corresponding second-forest identities are
`tech\jsmith` and `tech\johna`, with UPN suffix `tech.mcweeinc.com`. New hydrated
users receive the deployment `password`; existing users' passwords are not reset.
Verify hydration and use only the privileges required by the individual scenario.

The scripts' temporary users, such as `testuser`, `bad.user`, and `adm_backup`,
are **not** created by deployment. In particular, the honeytoken `adm_backup`
is different from hydrated `admin_bak`. Do not use the deployment administrator
or hydrated users as disposable creation/deletion targets.

## Machines and roles

These are VM names and the computer names requested by the shared VM module.

| Machine | Operating system | Image SKU | Private IP | Scenario role |
| --- | --- | --- | --- | --- |
| `LabSubAd1` | Windows Server 2022 Datacenter | `2022-Datacenter` | `10.0.2.15` | First-forest AD DS/DNS and primary scenario target; default FQDN `LabSubAd1.mayor.mcweeinc.com`. |
| `LabSubAd2` | Windows Server 2022 Datacenter | `2022-Datacenter` | `10.0.2.16` | Independent second-forest controller; default FQDN `LabSubAd2.tech.mcweeinc.com`. |
| `Win2022` | Windows Server 2022 Datacenter | `2022-Datacenter` | `10.0.2.50` | Optional member-server target; join the selected forest before domain-dependent use. |
| `WinClient11` | Windows 11 23H2 Enterprise | `win11-23h2-ent` | `10.0.2.51` | Scenario source workstation; domain joining and RSAT installation are manual prerequisites. |

## Before running a scenario

Connect through the lab VPN and verify the source computer with `hostname` or
`$env:COMPUTERNAME`, and the account with `whoami`. For first-forest examples,
configure `WinClient11` to use `10.0.2.15` for AD DNS, join
`mayor.mcweeinc.com`, and sign in with the account needed for that scenario.
Install RSAT/Active Directory PowerShell tools where required. Domain joining
and MDI sensor onboarding are **not automatic**.

Hydration does not grant standard users RDP access to member machines. Use the
deployment administrator for initial setup and configure any needed sign-in
rights before using `mayor\jsmith` for a scenario.

Check hydration on `LabSubAd1`, install/configure MDI sensors on the controllers,
and verify sensor health and tenant settings before expecting detections.
Use `LabSubAd1` for AD administration if a scenario requires tools or privileges
not yet configured on the client. Do not assume AD discovery reaches the second
forest or that first-forest credentials work there. For second-forest exercises,
use `10.0.2.16` for AD DNS and complete that forest's membership and access setup
separately. The staged `run-victimpc.ps1` uses unrelated `Contoso` names; it is
not an automatically executed domain-join step.

## Scenarios

* [Account Over Permissions](./AccountOverPermissions.md)
* [DNS Zone Transfer](./DnsZoneTransfer.md)
* [Honey Token Account](./HoneytokenAccount.md)
* [LDAP Recon](./LdapRecon.md)
* [Net / SMB Session Enumeration](./NetSessionEnumeration.md)
* [Network Mapping Recon](./NetworkMappingRecon.md)
* [Remote Code Execution](./RemoteCodeExecution.md)
* [Suspicious Account Addition](./SuspiciousAccountAddition.md)

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

## Cleanup

Run cleanup in the same forest and against the same scenario-created accounts
used for execution. Do not delete deployment administrators or hydrated users.
The [honeytoken guide](HoneytokenAccount.md#clean-up) documents a specific
overlap: the script's cleanup deletes `Remote IT Admin`, which hydration already
uses for `admin_bak`. Preserve that group and remove only the temporary decoy.
For full environment removal, follow [lab teardown](../../docs/getting-started.md).
Shutdown alone does not remove billable infrastructure.

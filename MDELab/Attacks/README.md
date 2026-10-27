# MDE Lab Attack Scenarios

## Deployment context

These instructions describe the standalone [MDE deployment](../README.md) and
its [Bicep entrypoint](../modules/mdelab.bicep). Names and addresses below match
that deployment, not the MDI, Linux, or OceanLotus environments. If you deployed
the [unified Defender lab](../../Defender/README.md), use its inventory instead:
for example, its `WinClient11` is `10.0.2.40`, not `10.0.2.53`.

Examples assume the default `domainName` of `mcweeinc.com` and
`domainNetbiosName` of `mcwee`. Substitute your deployment values if overridden.
Published templates and runtime scripts can lag source; check the
[deployment alignment notes](../../docs/deployment-alignment.md) and actual
machines before running a scenario.

## Accounts and sign-in

The `username` deployment parameter defaults to `cmadmin`. Use the supplied
`password` to sign in to a non-domain-joined Windows member machine as
`.\cmadmin`, or to `LinuxUbuntu` as `cmadmin`. Substitute your chosen username
if you changed that parameter. This VM administrator is not one of the
scenario users below.

Azure deployment and Defender portal access use your own authorized tenant
account. These VM/domain credentials do not create cloud identities or grant
tenant roles.

After `LabAd` promotion, restart, and sign-in complete the staged
[DcHydrate.ps1](../../Common/DSC/DcHydrate.ps1), the `LabUsers` OU contains:

| Display name | Account name | Additional groups assigned by hydration |
| --- | --- | --- |
| John Smith | `jsmith` | None. |
| Jeff Leatherman | `jeffl` | None. |
| Ron HelpDesk | `ronhd` | Helpdesk. |
| John Admin | `johna` | Domain Admins. |
| Samira Abbasi | `samiraa` | Domain Admins. |
| Admin Backup | `admin_bak` | Remote IT Admin; Admin Backup. |

With default domain parameters, domain sign-ins include `mcwee\jsmith` and
`mcwee\johna`, or `jsmith@mcweeinc.com` and `johna@mcweeinc.com`. New hydrated
accounts receive the deployment `password`; hydration does not reset passwords
of accounts that already exist. Verify hydration before using these identities.
Use `jsmith` for standard-user domain steps and `johna` only when domain
administration is required. These accounts do not automatically gain local
administrator rights on unjoined member machines.

Accounts created by simulations, such as `BackdoorAdmin` or a user chosen for
advanced hunting, are separate temporary test accounts. Do not substitute the
deployment administrator or hydrated users into account-creation/deletion steps.

## Machines and roles

These are VM names and the computer names requested by the shared VM module.
Windows scenario scripts do not run on `LinuxUbuntu`.

| Machine | Operating system | Image SKU | Private IP | Scenario role |
| --- | --- | --- | --- | --- |
| `LabAd` | Windows Server 2022 Datacenter | `2022-Datacenter` | `10.0.2.5` | AD DS, DNS, and hydrated domain accounts; not the default host for local-account simulations. |
| `Win2016` | Windows Server 2016 Datacenter | `2016-Datacenter` | `10.0.2.50` | Optional Windows server target when the scenario supports its OS/build. |
| `Win2022` | Windows Server 2022 Datacenter | `2022-Datacenter` | `10.0.2.51` | Optional Windows server target when the scenario supports its OS/build. |
| `LinuxUbuntu` | Ubuntu Server 22.04 LTS | `22_04-lts-gen2` | `10.0.2.52` | Linux onboarding/configuration exercises only; not the Windows PowerShell scenarios below. |
| `WinClient11` | Windows 11 23H2 Enterprise | `win11-23h2-ent` | `10.0.2.53` | Starting host for Windows endpoint scenarios; verify OS/build compatibility first. |

## Before running a scenario

Connect to the lab VPN before using private IPs. Verify the machine name with
`hostname` or `$env:COMPUTERNAME` and the signed-in identity with `whoami`.
Use the VM administrator for elevated local steps on `WinClient11`; a domain
account is needed only for steps that query or change AD.

Hydration does not grant standard users RDP access to member machines. Use the
deployment administrator for initial setup, and configure any required sign-in
rights deliberately before using a domain user for a scenario.

Domain joining and MDE onboarding are **not automatic**. For domain-dependent
steps, configure member-machine DNS for `LabAd` (`10.0.2.5`), join the configured
domain, and sign in with the appropriate domain account. Install and onboard MDE
and verify device health before testing detection. Follow each script's OS,
privilege, safety, and cleanup requirements; choosing a deployed machine does not
guarantee that every technique works on that Windows build or generates an alert.

<a id="attack-scenarios"></a>

## Scenarios

1. [MDE Demonstration Scenarios (MS Learn)](https://learn.microsoft.com/en-us/defender-endpoint/defender-endpoint-demonstrations)
1. [Account Discovery](./AccountDiscovery.md)
1. [Account Persistence](./AccountPersistence.md)
1. [Credential Dumping](./CredentialDumping.md)
1. [Credential Dumping Schedule](./CredentialDumpingSchedule.md)
1. [Defender Tampering](./DefenderTampering.md)
1. [Delete Shadow Copy](./DeleteShadowCopy.md)
1. [Event Log Tampering](./EventLog.md)
1. [Password Detection](./PasswordDetection.md)
1. [Service Execution](./ServiceExecution.md)
1. [Service Execution Embedded EXE](./ServiceWithEmbeddedExe.md)
1. [UAC Bypass](./UACBypass.md)
1. [Account Advanced Hunting](./AccountAdvancedHunting.md)

### Account Discovery

Account discovery is a technique used by attackers to enumerate valid usernames and user accounts within a system or network. This reconnaissance activity helps adversaries identify existing accounts, enabling follow-on activities such as brute-forcing, spear-phishing attacks, privilege escalation, or lateral movement. Attackers may enumerate local users, local groups, and—on domain-joined machines—domain users and privileged groups like Domain Admins and Enterprise Admins.

### Account Persistence

Account persistence refers to techniques used by attackers to maintain long-term access to a system even after security measures are applied or the system is rebooted. Creating registry Run keys, Startup Folder entries, Boot/Logon Initialization Scripts, and scheduled tasks are common persistence techniques. By establishing these mechanisms, attackers ensure their malicious programs run automatically, maintaining their foothold across system reboots.

### Credential Dumping

Credential dumping is a technique used by attackers to extract stored authentication credentials—such as usernames, passwords, or hashes—from a system's memory or security databases. These credentials can then be used for lateral movement, privilege escalation, or unauthorized access to sensitive systems. This simulation demonstrates multiple credential extraction methods including LSASS memory dumping, SAM registry extraction, and browser credential theft.

### Credential Dumping Schedule

This simulation extends the standard credential dumping attack by executing credential extraction techniques through Windows Scheduled Tasks. By leveraging the Task Scheduler, attackers can execute credential dumping operations under the SYSTEM context, evade user-level monitoring, and establish recurring credential harvesting. This approach combines credential access techniques (LSASS dumping, SAM extraction, browser credential theft) with persistence and execution via scheduled tasks, making it harder to detect and attribute.

### Defender Tampering

Endpoint protection tampering refers to attempts by attackers to disable or modify security settings on a device to weaken its defenses. This can involve altering antivirus configurations, disabling real-time protection, adding broad exclusions, or modifying registry keys to bypass security controls. Attackers often perform these actions before deploying malware to avoid detection.

### Delete Shadow Copy

Shadow Copy Deletion is a technique commonly associated with ransomware attacks where attackers delete or disable built-in Windows shadow copies and recovery services. This prevents system recovery by denying access to backups, making it significantly more challenging for victims to restore corrupted or encrypted data. By removing these recovery options, attackers increase the pressure on victims to pay ransoms.

### Clear Event Log

Clear Windows Event Logs is a technique where attackers delete records in Windows Event Logs to erase evidence of their activities. This action is part of the Defense Evasion tactic, as it helps attackers avoid detection by removing traces of their unauthorized actions from the logs, making it harder for security teams to investigate or respond to the intrusion.

### Password Detection

Attackers will query the Registry and local file system to find credentials and passwords saved by programs, services, user-created credential files, shared credential stores, configuration files with system or service passwords, or source code and binaries with embedded credentials. These credentials may be used for automatic logons, enabling attackers to gain unauthorized access. Attackers then leverage the discovered password information to launch further attacks, such as unauthorized access, privilege escalation, or lateral movement within the network.

### Service Execution

Service Execution is a technique where attackers abuse the Windows Service Control Manager (services.exe) to run malicious commands or payloads. The Service Control Manager, which allows the management of system services, can be accessed by attackers through both graphical interfaces and command-line utilities like sc.exe and net. This enables them to execute code with service-level privileges, which can aid in establishing persistence or elevating privileges.

### Service With Embedded EXE

This simulation demonstrates how an attacker can compile malicious C# code directly on a target system and install the resulting executable as a Windows service. By embedding source code within a script and using the .NET compiler present on Windows systems, attackers can create and deploy custom service executables without needing to transfer pre-compiled binaries—evading file-based detection mechanisms that rely on known signatures.

### UAC Bypass

UAC Bypass is a technique where attackers elevate their privileges to gain administrator-level permissions without triggering a User Account Control (UAC) prompt. This allows them to perform restricted tasks without user confirmation, bypassing security checks that would typically prevent unauthorized actions. This simulation uses the sdclt.exe method (Backup and Restore utility) which exploits registry handler hijacking.

## Cleanup

Use each scenario's cleanup on the same machine and with the same temporary
account names used during execution. Preserve the deployment administrator and
hydrated AD users; local test-account commands should not be run on `LabAd`.
Restore any protections deliberately changed by a simulation. When finished
with the whole environment, follow [lab teardown](../../docs/getting-started.md);
VM shutdown alone does not remove billable disks and gateways.

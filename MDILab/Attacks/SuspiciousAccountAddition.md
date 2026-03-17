# Suspicious Account Addition

## Overview

This attack simulation demonstrates a common persistence technique where an attacker adds a compromised or newly created user account to sensitive groups such as Domain Admins. Microsoft Defender for Identity (MDI) monitors for suspicious modifications to sensitive groups and generates alerts when unusual additions are detected.

This type of attack is commonly used after an attacker gains initial access to establish persistence and escalate privileges within an Active Directory environment.

## Attack Simulation

### Prerequisites

- Domain-joined Windows machine with PowerShell
- Active Directory PowerShell module installed
- Domain Admin or Account Operator privileges (to add users to sensitive groups)
- Existing user account in the domain (or use `-CreateUser` to create one)

### Script: Invoke-SuspiciousAccountAddition.ps1

The `Invoke-SuspiciousAccountAddition.ps1` script automates the simulation of adding a user to a sensitive domain group.

#### Parameters

| Parameter | Type | Default | Description |
| -- | -- | -- | -- |
| `-UserName` | String | `bad.user` | The username to add to the domain group |
| `-DomainGroup` | String | `Domain Admins` | The domain group to add the user to |
| `-CreateUser` | Switch | - | Creates the user account if it doesn't exist |
| `-Password` | String | `P@ssw0rd123!` | Password for the new user account (used with `-CreateUser`) |
| `-Cleanup` | Switch | - | Removes the user from the group instead of adding |
| `-DeleteUser` | Switch | - | Deletes the user account (used with `-Cleanup`) |

### Usage Examples

#### Basic Usage - Add existing user to Domain Admins

```powershell
.\Invoke-SuspiciousAccountAddition.ps1
```

Adds the default user `bad.user` to the `Domain Admins` group.

#### Add a specific user to a specific group

```powershell
.\Invoke-SuspiciousAccountAddition.ps1 -UserName "testuser" -DomainGroup "Enterprise Admins"
```

#### Create a new user and add to Domain Admins

```powershell
.\Invoke-SuspiciousAccountAddition.ps1 -CreateUser
```

Creates a new user account `bad.user` with the default password and adds it to Domain Admins.

#### Create a user with custom credentials

```powershell
.\Invoke-SuspiciousAccountAddition.ps1 -UserName "attacker" -CreateUser -Password "SecureP@ss123!"
```

#### Cleanup - Remove user from group

```powershell
.\Invoke-SuspiciousAccountAddition.ps1 -Cleanup
```

Removes `bad.user` from the `Domain Admins` group.

#### Full cleanup - Remove from group and delete user

```powershell
.\Invoke-SuspiciousAccountAddition.ps1 -Cleanup -DeleteUser
```

Removes `bad.user` from `Domain Admins` and deletes the user account from Active Directory.

### Expected Output

```
[*] Domain: contoso.com
[*] Starting suspicious account addition simulation...
[*] Target User: bad.user
[*] Target Group: Domain Admins
[+] User found: CN=bad.user,CN=Users,DC=contoso,DC=com
[+] Group found: CN=Domain Admins,CN=Users,DC=contoso,DC=com
[*] Adding user 'bad.user' to group 'Domain Admins'...
[+] Successfully added 'bad.user' to 'Domain Admins'!
[*] This action may trigger security alerts in Microsoft Defender for Identity.
```

## Expected MDI Alert

After running the simulation, Microsoft Defender for Identity should generate an alert within a few minutes:

- **Alert Type:** Suspicious additions to sensitive groups
- **Severity:** Medium to High
- **Category:** Persistence
- **Timeline:** Alert typically appears within 5-15 minutes of the action

## Remediation Steps

1. Immediately remove the unauthorized user from the sensitive group
1. Disable or delete the suspicious user account
1. Review audit logs to identify the source of the attack
1. Check for other persistence mechanisms (scheduled tasks, services, etc.)
1. Reset passwords for any potentially compromised accounts
1. Review group membership of all sensitive groups
 
## MITRE ATT&CK Mapping

| Tactic | Technique | ID |
| -- | -- | -- |
| Persistence | Account Manipulation | T1098 |
| Persistence | Create Account | T1136 |
| Persistence | Domain Account | T1136.002 |
| Privilege Escalation | Domain Policy Modification | T1484 |

## Detections

| Alert Title | Alert Description | Alert Details |
| -- | -- | -- |
| Suspicious additions to sensitive groups | *account* added 2 accounts to 5 sensitive groups. | **Category:** Persistence<br/>**MITRE ATT&CK Techniques:** T1098: Account Manipulation, T1136: Create Account, T1136.002: Domain Account<br/>**Service source:** MDI<br/>**Detection source:** MDI<br/>**Detection technology:** -<br/>**Detection status:** Unknown |
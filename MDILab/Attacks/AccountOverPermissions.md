# Account Over-Permissions (Privilege Escalation via Group Membership)

## Overview

This attack simulation demonstrates a privilege escalation technique where an attacker creates or leverages an existing domain account and adds it to multiple highly privileged groups simultaneously. Unlike a targeted addition to a single group, this script escalates an account across several sensitive groups at once — including Domain Admins, Enterprise Admins, Schema Admins, Account Operators, and Backup Operators — mimicking an aggressive privilege escalation or insider threat scenario.

Microsoft Defender for Identity (MDI) monitors for suspicious modifications to sensitive groups and generates alerts when unusual or bulk additions are detected.

## MITRE ATT&CK Mapping

| Tactic | Technique | ID |
| -- | -- | -- |
| Persistence | Account Manipulation | T1098 |
| Privilege Escalation | Account Manipulation | T1098 |
| Persistence | Create Account: Domain Account | T1136.002 |
| Defense Evasion | Valid Accounts: Domain Accounts | T1078.002 |

## Attack Simulation

### Prerequisites

- Domain-joined Windows machine with PowerShell
- Active Directory PowerShell module installed (`RSAT-AD-PowerShell`)
- Domain Admin or equivalent privileges to manage group memberships
- Network connectivity to a domain controller

### Script: Invoke-AccountOverPermissions.ps1

The `Invoke-AccountOverPermissions.ps1` script manages domain account group memberships for privilege escalation testing. It can create a new account, add it to multiple privileged groups, and clean up afterward.

#### Parameters

| Parameter | Type | Default | Description |
| -- | -- | -- | -- |
| `-UserName` | String | *(Required)* | The username of the domain account to manage |
| `-CreateUser` | Switch | - | Creates a new domain user account if it doesn't exist |
| `-Password` | SecureString | *(Auto-generated)* | Password for the new user account (used with `-CreateUser`) |
| `-GroupList` | String[] | `Domain Admins`, `Enterprise Admins`, `Schema Admins`, `Account Operators`, `Backup Operators` | Array of domain groups to add the user to |
| `-CleanUp` | Switch | - | Removes the user from all specified groups instead of adding |
| `-DeleteUser` | Switch | - | Deletes the user account entirely (requires `-CleanUp`) |
| `-DomainController` | String | - | Optional domain controller to target for operations |

#### What the Script Does

1. **Add Mode** (default): Creates a new user (if `-CreateUser` is specified) or uses an existing account, then adds it to all groups in `-GroupList`
2. **CleanUp Mode**: Removes the user from all specified groups and optionally deletes the account with `-DeleteUser`
3. Generates a random secure password if none is provided when creating a user
4. Logs all operations with timestamps and color-coded status messages

## Setup

Use the [Invoke-AccountOverPermissions.ps1](./Invoke-AccountOverPermissions.ps1) script to simulate the privilege escalation.

### Usage Examples

#### Create a new user and add to all default privileged groups

```powershell
.\Invoke-AccountOverPermissions.ps1 -UserName "testuser" -CreateUser
```

Creates `testuser` and adds it to Domain Admins, Enterprise Admins, Schema Admins, Account Operators, and Backup Operators.

#### Add an existing user to specific groups

```powershell
.\Invoke-AccountOverPermissions.ps1 -UserName "testuser" -GroupList @("Domain Admins", "Backup Operators")
```

Adds an existing user to only the specified groups.

#### Add user targeting a specific domain controller

```powershell
.\Invoke-AccountOverPermissions.ps1 -UserName "testuser" -CreateUser -DomainController "DC01.contoso.com"
```

#### Clean up — remove user from all groups

```powershell
.\Invoke-AccountOverPermissions.ps1 -UserName "testuser" -CleanUp
```

Removes `testuser` from all default privileged groups.

#### Full clean up — remove from groups and delete account

```powershell
.\Invoke-AccountOverPermissions.ps1 -UserName "testuser" -CleanUp -DeleteUser
```

### Expected Output

```
[2026-03-05 10:30:00] [Info] Importing Active Directory module...
[2026-03-05 10:30:01] [Info] Working with domain: contoso.com
[2026-03-05 10:30:01] [Info] Starting privilege escalation operations for user: testuser
[2026-03-05 10:30:01] [Info] Creating new user account: testuser
[2026-03-05 10:30:01] [Warning] Generated password for user 'testuser': xK#9mL$2pQ...
[2026-03-05 10:30:01] [Warning] SAVE THIS PASSWORD - it will not be displayed again!
[2026-03-05 10:30:02] [Success] User created successfully: CN=testuser,CN=Users,DC=contoso,DC=com
[2026-03-05 10:30:02] [Info] Adding user to privileged groups...
[2026-03-05 10:30:02] [Success] Added to group: Domain Admins
[2026-03-05 10:30:02] [Success] Added to group: Enterprise Admins
[2026-03-05 10:30:02] [Success] Added to group: Schema Admins
[2026-03-05 10:30:02] [Success] Added to group: Account Operators
[2026-03-05 10:30:03] [Success] Added to group: Backup Operators
[2026-03-05 10:30:03] [Info] Operation complete. Added: 5, Already member: 0, Failed: 0
[2026-03-05 10:30:03] [Success] User 'testuser' has been granted extensive privileges!
[2026-03-05 10:30:03] [Warning] WARNING: This account now has elevated permissions. Use responsibly in lab environments only.
```

## Scenario Execution

1. Run the script with `-CreateUser` to create a test account and add it to all privileged groups
2. Wait 5–15 minutes for MDI to process the activity
3. Check the Microsoft Security Portal for generated alerts
4. Run cleanup when testing is complete

## Expected Alerts

| Alert Title | Alert Description | Severity | Timeline |
| -- | -- | -- | -- |
| Suspicious additions to sensitive groups | Account was added to multiple sensitive groups | Medium–High | 5–15 minutes |

| Alert Title | Alert Description | Alert Details |
| -- | -- | -- |
| Suspicious additions to sensitive groups | *account* added accounts to sensitive groups. | **Category:** Persistence<br/>**MITRE ATT&CK Techniques:** T1098: Account Manipulation, T1136: Create Account, T1136.002: Domain Account<br/>**Service source:** MDI<br/>**Detection source:** MDI<br/>**Detection technology:** Behavioral analytics<br/>**Detection status:** Unknown |

## Why Does This Matter

1. **Bulk privilege escalation** — Adding an account to multiple sensitive groups at once is a strong indicator of compromise or insider threat
2. **Persistence** — Attackers use over-permissioned accounts to maintain access even if one group membership is discovered and removed
3. **Lateral movement enablement** — Enterprise Admins and Schema Admins provide forest-wide access, far exceeding typical lateral movement
4. **Defense evasion** — By granting redundant privileges across multiple groups, attackers create fallback access paths
5. **High-fidelity detection** — Legitimate administrative changes rarely involve adding an account to five privileged groups simultaneously

## Best Practices

1. Monitor sensitive group membership changes with MDI and audit policies
2. Use Privileged Access Management (PAM) or Just-In-Time (JIT) access to limit standing privileges
3. Implement tiered administration to prevent a single account from holding multiple sensitive group memberships
4. Enable alerts for any modification to Enterprise Admins, Schema Admins, and Domain Admins
5. Regularly audit group memberships for unexpected or unauthorized accounts
6. Use the principle of least privilege — avoid assigning users to groups they don't need

## Clean-Up

Remove the test account from all groups and delete it:

```powershell
.\Invoke-AccountOverPermissions.ps1 -UserName "testuser" -CleanUp -DeleteUser
```

Or remove from groups only (keep the account):

```powershell
.\Invoke-AccountOverPermissions.ps1 -UserName "testuser" -CleanUp
```

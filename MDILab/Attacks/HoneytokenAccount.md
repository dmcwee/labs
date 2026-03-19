# Honeytoken Account Activity Detection

## Overview

Honeytoken accounts are decoy accounts strategically placed in an environment to act as early warning indicators of malicious activity. These accounts are intentionally made to appear valuable (e.g., administrative accounts with enticing names) but are never used for legitimate purposes. Any authentication attempt, LDAP query, or interaction with a honeytoken account is immediately suspicious and indicates potential reconnaissance or credential theft activity.

Microsoft Defender for Identity (MDI) can monitor tagged honeytoken accounts and generate alerts when any activity is detected, providing high-fidelity detection with minimal false positives.

## MITRE ATT&CK Mapping

| Tactic | Technique | ID |
| -- | -- | -- |
| Discovery | Account Discovery | T1087 |
| Discovery | Domain Account | T1087.002 |
| Credential Access | Brute Force | T1110 |
| Initial Access | Valid Accounts | T1078 |

## Attack Simulation

### Prerequisites

- Domain-joined Windows machine with PowerShell
- Active Directory PowerShell module installed
- Domain Admin or Account Operator privileges (to create accounts)
- Access to Microsoft Defender for Identity portal (to tag the honeytoken)

### Script: Invoke-HoneyTokenAccount.ps1

The `Invoke-HoneyTokenAccount.ps1` script automates the creation of a honeytoken account and an associated enticing group to make the account appear valuable to attackers.

#### Parameters

| Parameter | Type | Default | Description |
| -- | -- | -- | -- |
| `-Username` | String | `adm_backup` | The username for the honeytoken account |
| `-Password` | String | `P@ssw0rd!TestOnly` | Password for the honeytoken account |
| `-Description` | String | `Decoy honeytoken - do not use (lab only)` | Description for the account (use a convincing description in production) |
| `-OU` | String | `CN=Users` | Organizational Unit path where the account will be created |
| `-Cleanup` | Switch | - | Removes the honeytoken account and group |
| `-Force` | Switch | - | Skips the confirmation prompt |

#### What the Script Creates

1. **User Account** - A domain user with the specified name and password
2. **Security Group** - A "Remote IT Admin" global security group (appears valuable)
3. **Group Membership** - Adds the honeytoken user to the Remote IT Admin group

## Setup

Use the [Invoke-HoneyTokenAccount.ps1](./Invoke-HoneyTokenAccount.ps1) script to create the honeytoken account and associated group.

### Usage Examples

#### Create default honeytoken account

```powershell
.\Invoke-HoneyTokenAccount.ps1
```

Creates `adm_backup` account in `CN=Users` and adds it to the `Remote IT Admin` group.

#### Create honeytoken with custom username

```powershell
.\Invoke-HoneyTokenAccount.ps1 -Username "svc_sql_backup"
```

Creates a service account-styled honeytoken that appears to be for SQL backups.

#### Create honeytoken in specific OU

```powershell
.\Invoke-HoneyTokenAccount.ps1 -Username "Admin2" -OU "OU=AdminAccounts"
```

Creates the honeytoken in a specific OU to blend with legitimate admin accounts.

#### Create honeytoken with custom description (production use)

```powershell
.\Invoke-HoneyTokenAccount.ps1 -Username "adm_emergency" -Description "Emergency admin account - IT Security" -Force
```

Creates an account with a convincing description for production deployment.

### Expected Output

```
========================================
HONEYTOKEN ACCOUNT CREATION
========================================
This script will CREATE the following:
  + User: adm_backup
  + UPN: adm_backup@contoso.com
  + Path: CN=Users,DC=contoso,DC=com
  + Group: Remote IT Admin
  + Description: Decoy honeytoken - do not use (lab only)
========================================

Do you want to continue? (Y/N): Y
Created group: Remote IT Admin
Added adm_backup to Remote IT Admin
```

### Tag the Honeytoken in MDI

After creating the honeytoken account, you must tag it in Microsoft Defender for Identity for monitoring.

**Reference:** [Entity tags in Microsoft Defender for Identity](https://learn.microsoft.com/en-us/defender-for-identity/entity-tags)

1. Open the **Microsoft Security Portal** (security.microsoft.com)
2. Navigate to **Settings** → **Identities**
3. Under **Entity Tags**, select **Honeytoken**
4. Click **+ Tag users**
5. Search for and select the `adm_backup` user (or your custom honeytoken name)
6. Click **Add selection**
7. Confirm the account appears in the Honeytoken list

> **Note:** It may take up to 2 hours for the tag to propagate to all sensors.


## Scenario Execution

Use the following scenarios to trigger Honeytoken account detections.

### Scenario 1: Authentication Attempt

Any authentication attempt against the honeytoken triggers an alert, regardless of success or failure.

From a testing machine, open a command prompt:

```cmd
runas /user:CONTOSO\adm_backup cmd
```

> Replace `CONTOSO\adm_backup` with your domain and honeytoken account name.

When prompted, enter either the correct or an incorrect password—both scenarios generate a detection.

**Expected Results:**
- **Alert:** "Honeytoken user authentication activity"
- **Advanced Hunting:** Records in `IdentityLogonEvents` table
- **Reference:** [Honeytoken activity IdentityLogonEvents](https://learn.microsoft.com/en-us/defender-xdr/advanced-hunting-identitylogonevents-table)

### Scenario 2: LDAP Query

Any LDAP query targeting the honeytoken account triggers an alert.

From the testing machine, open a command prompt:

```cmd
net user adm_backup /domain
```

> Replace `adm_backup` with your honeytoken account name.

**Expected Results:**
- **Alert:** "Honeytoken user was queried via LDAP"
- **Advanced Hunting:** Records in `IdentityQueryEvents` (ActionType: LDAP query)
- **Reference:** [IdentityQueryEvents table](https://learn.microsoft.com/en-us/defender-xdr/advanced-hunting-identityqueryevents-table)

### Scenario 3: Kerberos Ticket Request

Request a Kerberos ticket for the honeytoken account:

```cmd
klist get CONTOSO\adm_backup
```

This simulates an attacker attempting to use the honeytoken credentials.

## Expected MDI Alerts

| Trigger | Alert Title | Severity | Timeline |
| -- | -- | -- | -- |
| Authentication (success/fail) | Honeytoken user authentication activity | High | 5-15 minutes |
| LDAP query | Honeytoken user was queried via LDAP | Medium | 5-15 minutes |
| Kerberos ticket | Honeytoken user authentication activity | High | 5-15 minutes |

## Why Honeytokens are Effective

1. **Zero false positives** - Legitimate users never use honeytoken accounts
2. **Early detection** - Catches attackers during reconnaissance before damage occurs
3. **Insider threat detection** - Identifies employees exploring accounts they shouldn't access
4. **Credential theft indicator** - Authentication attempts indicate stolen credential usage
5. **Low maintenance** - No ongoing tuning required after initial setup

## Best Practices for Honeytoken Accounts

1. **Make them attractive** - Use names like `adm_backup`, `svc_sql`, `IT_Admin`
2. **Place strategically** - Put them in OUs where attackers would look
3. **Add to interesting groups** - The "Remote IT Admin" group makes them appear valuable
4. **Don't use obvious descriptions** - Avoid "DO NOT USE" in production
5. **Create multiple honeytokens** - Different types across different OUs
6. **Never use for legitimate purposes** - Any activity is suspicious by definition

## Clean-Up

Remove the honeytoken account and group when testing is complete:

```powershell
.\Invoke-HoneyTokenAccount.ps1 -Cleanup
```

Or for a specific custom username:

```powershell
.\Invoke-HoneyTokenAccount.ps1 -Cleanup -Username "Admin2"
```

> **Remember:** Also remove the entity tag from the MDI portal if permanently removing the honeytoken.

## Detections

| Alert Title | Alert Description | Alert Details |
| -- | -- | -- |
| Honeytoken authentication activity | *honey token account* performed *x* suspicious activities. | **Category:** Credential Access<br/>**MITRE ATT&CK Techniques:** T1087: Account Discovery, T1087.002: Domain Account<br/>**Service source:** MDI<br/>**Detection source:** MDI<br/>**Detection technology:** Behavioral analytics<br/>**Detection status:** Active |
| Honeytoken user was queried via LDAP | A user queried the honeytoken account via LDAP. | **Category:** Discovery<br/>**MITRE ATT&CK Techniques:** T1087: Account Discovery<br/>**Service source:** MDI<br/>**Detection source:** MDI<br/>**Detection technology:** Behavioral analytics<br/>**Detection status:** Active |
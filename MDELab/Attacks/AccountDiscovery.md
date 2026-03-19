# Account Discovery

## Overview

Account discovery is a technique used by attackers to enumerate valid usernames and user accounts within a system or network. This reconnaissance activity helps adversaries identify existing accounts, enabling follow-on activities such as brute-forcing, spear-phishing attacks, privilege escalation, or lateral movement. Attackers may enumerate local users, local groups, and—on domain-joined machines—domain users and privileged groups like Domain Admins and Enterprise Admins.

## MITRE ATT&CK Mapping

| Tactic | Technique ID | Technique Name |
| --- | --- | --- |
| Discovery | T1033 | System Owner/User Discovery |
| Discovery | T1069.001 | Permission Groups Discovery: Local Groups |
| Discovery | T1069.002 | Permission Groups Discovery: Domain Groups |
| Discovery | T1087 | Account Discovery |
| Discovery | T1087.001 | Account Discovery: Local Account |
| Discovery | T1087.002 | Account Discovery: Domain Account |

## Expected Alerts

| Alert Title | Alert Description | Alert Details |
| --- | --- | --- |
| Suspicious sequence of exploration activities | A process performed multiple suspicious exploration activities in a short time, including user and group enumeration. This may indicate reconnaissance activity by an attacker mapping the environment. | **Category:** Discovery<br/>**MITRE ATT&CK Techniques:** T1033: System Owner/User Discovery, T1069: Permission Groups Discovery, T1087: Account Discovery<br/>**Service source:** Microsoft Defender for Endpoint<br/>**Detection source:** EDR<br/>**Detection technology:** Behavior<br/>**Detection status:** Detected |

## Attack Simulation

### Prerequisites

- Windows 10/11 or Windows Server test environment
- PowerShell with execution policy allowing script execution
- For domain enumeration: domain-joined machine with Active Directory PowerShell module (RSAT)
- Microsoft Defender for Endpoint onboarded device

### Script: Invoke-AccountDiscoverySimulation.ps1

#### Parameters

| Parameter | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `OutputPath` | String | No | `$env:TEMP\Discovery` | Directory where enumerated account data is saved |
| `CleanUp` | Switch | No | — | Removes all files and folders created by the simulation |
| `Force` | Switch | No | — | Skip the confirmation prompt before execution |

#### What the Script Does

1. **Local User Enumeration** — Enumerates all local users using `Get-LocalUser` and saves results to `Users.txt`.
2. **Local Group Enumeration** — Enumerates all local groups using `Get-LocalGroup` and saves to `Groups.txt`.
3. **Local Group Membership** — Enumerates members of each local group and saves individual files per group (`<GroupName>-Members.txt`).
4. **Domain Enumeration** (if domain-joined) — Automatically detects if the machine is domain-joined and:
   - Checks for ActiveDirectory PowerShell module (attempts to install RSAT if missing and running as admin)
   - Enumerates all domain users via `Get-ADUser`
   - Enumerates Domain Admins group members
   - Enumerates Enterprise Admins group members

## Setup

### Usage Examples

```powershell
# Run the full simulation (automatically includes domain if joined)
.\Invoke-AccountDiscoverySimulation.ps1

# Run with Force to skip the confirmation prompt
.\Invoke-AccountDiscoverySimulation.ps1 -Force

# Specify a custom output path
.\Invoke-AccountDiscoverySimulation.ps1 -OutputPath "C:\Temp\Discovery"

# Clean up all simulation artifacts
.\Invoke-AccountDiscoverySimulation.ps1 -CleanUp
```

### Expected Output

After running the simulation, the following files will be created in the output directory:

**Local enumeration (always performed):**

- `Users.txt` — List of all local user accounts with Name, Enabled status, and Description
- `Groups.txt` — List of all local groups with Name and Description
- `<GroupName>-Members.txt` — One file per local group containing its members

**Domain enumeration (if domain-joined):**

- `domain-users.txt` — List of all domain users with DisplayName, SamAccountName, and Name
- `domain-admins.txt` — Members of the Domain Admins group
- `enterprise-admins.txt` — Members of the Enterprise Admins group

## Scenario Execution

1. Open PowerShell on the target Windows machine
2. Navigate to the Attacks directory: `cd C:\path\to\MDELab\Attacks`
3. Run the simulation script: `.\Invoke-AccountDiscoverySimulation.ps1`
4. Review the confirmation prompt and press `Y` to continue (or use `-Force` to skip)
5. Wait for the enumeration to complete
6. Review the generated files in the output directory (`$env:TEMP\Discovery` by default)
7. Monitor the Microsoft Defender for Endpoint portal for alerts
8. Run cleanup when finished: `.\Invoke-AccountDiscoverySimulation.ps1 -CleanUp`

## Why Does This Matter

Account discovery is often one of the first steps attackers take after gaining initial access to a system. By understanding what accounts exist and which users have elevated privileges, attackers can:

- **Plan lateral movement** — Identify high-value targets like Domain Admins for credential theft
- **Prioritize attacks** — Focus on accounts with administrative privileges
- **Craft targeted attacks** — Use discovered usernames for spear-phishing or password spraying
- **Map the environment** — Understand the organization's structure and identify key personnel
- **Identify security gaps** — Find service accounts, stale accounts, or accounts with weak configurations

Detecting this reconnaissance activity early provides defenders an opportunity to respond before attackers can leverage the gathered intelligence for more damaging actions.

## Best Practices

- **Monitor for bulk enumeration** — Alert on processes that enumerate multiple accounts or groups in rapid succession
- **Implement least privilege** — Limit which accounts can query Active Directory for user and group information
- **Enable PowerShell logging** — Configure Script Block Logging and Module Logging to capture enumeration commands
- **Review audit policies** — Enable auditing for directory service access and account enumeration events (Event IDs 4798, 4799)
- **Segment sensitive groups** — Use tiered administration to protect high-privilege accounts from discovery
- **Monitor LDAP queries** — Track unusual Active Directory queries from workstations

## Clean-Up

```powershell
# Using the script
.\Invoke-AccountDiscoverySimulation.ps1 -CleanUp

# Manual cleanup
$OutputPath = "$env:TEMP\Discovery"
Remove-Item -Path $OutputPath -Recurse -Force
```

## References

- [MITRE ATT&CK T1087 - Account Discovery](https://attack.mitre.org/techniques/T1087/)
- [MITRE ATT&CK T1069 - Permission Groups Discovery](https://attack.mitre.org/techniques/T1069/)
- [MITRE ATT&CK T1033 - System Owner/User Discovery](https://attack.mitre.org/techniques/T1033/)
- [Microsoft Docs - Get-LocalUser](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.localaccounts/get-localuser)
- [Microsoft Docs - Get-ADUser](https://docs.microsoft.com/en-us/powershell/module/activedirectory/get-aduser)
- [Microsoft Defender for Endpoint - Investigate alerts](https://docs.microsoft.com/en-us/microsoft-365/security/defender-endpoint/investigate-alerts)

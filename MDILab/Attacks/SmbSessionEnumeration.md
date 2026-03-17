# SMB Session Enumeration (Net Session Enumeration)

## Overview

SMB Session Enumeration is a reconnaissance technique used by attackers to discover active user sessions on remote computers within a network. By enumerating SMB sessions, attackers can identify:

- Which users are currently logged into which machines
- Potential targets for lateral movement
- High-value targets such as Domain Admins with active sessions
- Network topology and user behavior patterns

This technique is commonly used during the discovery phase of an attack, particularly when an attacker is attempting to locate privileged accounts for credential theft or lateral movement.

Users and computers need to at least access the SYSVOL share to retrieve GPOs. Attackers can use this information to know where users recently signed in and move laterally in the network to get to a specific sensitive account.

## MITRE ATT&CK Mapping

| Tactic | Technique | ID |
| -- | -- | -- |
| Discovery | System Network Connections Discovery | T1049 |
| Discovery | Remote System Discovery | T1018 |
| Lateral Movement | Remote Services: SMB/Windows Admin Shares | T1021.002 |

## Attack Simulation

### Prerequisites

- Domain-joined Windows machine with PowerShell
- Network connectivity to target domain controller or server
- Standard domain user account (enumeration may work with limited privileges)
- For full results: Administrative privileges on the target machine

### Script: Invoke-NetSessionEnumeration.ps1

The `Invoke-NetSessionEnumeration.ps1` script uses the Windows `NetSessionEnum` API to retrieve information about established SMB sessions on a target computer.

#### Parameters

| Parameter | Type | Default | Description |
| -- | -- | -- | -- |
| `-ComputerName` | String | Local computer | The name of the computer to query for sessions |
| `-ClientName` | String | - | Filter results to only show sessions from a specific client computer |
| `-UserName` | String | - | Filter results to only show sessions for a specific user |

#### Output Fields

| Field | Description |
| -- | -- |
| ComputerName | The target computer that was queried |
| ClientName | The client machine where the session originated |
| UserName | The username associated with the session |
| ActiveTime | Duration the session has been active |
| IdleTime | Duration the session has been idle |

### Usage Examples

#### Enumerate sessions on local computer

```powershell
.\Invoke-NetSessionEnumeration.ps1
```

Lists all active SMB sessions on the local computer.

#### Enumerate sessions on a remote server

```powershell
.\Invoke-NetSessionEnumeration.ps1 -ComputerName "DC01"
```

Lists all sessions on the domain controller DC01. This is the most common attack scenario as domain controllers typically have sessions from many users.

#### Enumerate sessions on multiple domain controllers

```powershell
Get-ADDomainController -Filter * | ForEach-Object {
    .\Invoke-NetSessionEnumeration.ps1 -ComputerName $_.HostName
}
```

Enumerates sessions across all domain controllers to find where privileged users are logged in.

#### Filter sessions for a specific user

```powershell
.\Invoke-NetSessionEnumeration.ps1 -ComputerName "DC01" -UserName "admin"
```

Lists only sessions for user 'admin' on DC01 - useful for hunting specific high-value targets.

#### Filter sessions from a specific client

```powershell
.\Invoke-NetSessionEnumeration.ps1 -ComputerName "DC01" -ClientName "WORKSTATION01"
```

Lists sessions originating from WORKSTATION01.

### Expected Output

```
ComputerName ClientName    UserName       ActiveTime       IdleTime
------------ ----------    --------       ----------       --------
DC01         WORKSTATION01 john.smith     00:45:23         00:02:15
DC01         WORKSTATION02 jane.admin     01:23:45         00:00:30
DC01         SERVER01      svc_backup     12:34:56         00:00:00
```

### Error Codes

| Error Code | Meaning |
| -- | -- |
| 5 | Access denied - requires administrative privileges |
| 53 | Network path not found - unable to contact target |
| 2312 | No sessions found on the target computer |

## Detections

| Alert Title | Alert Description | Alert Details |
| -- | -- | -- |
| Suspicious Server Message Block (SMB) enumeration from untrusted host | Suspicious SMB session enumeration targeting the MDI sensor. This indicates adversary reconnaissance aimed at identifying active user sessions on the host. | **Category:** Discovery<br/>**MITRE ATT&CK Techniques:** T1049: System Network Connections Discovery<br/>**Service source:** MDI<br/>**Detection source:** Defender XDR<br/>**Detection technology:** -<br/>**Detection status:** Unknown |

## Why This is Suspicious

MDI detects this activity as suspicious because:

1. **Uncommon behavior** - Most legitimate tools don't enumerate sessions across multiple machines
2. **Reconnaissance indicator** - This technique is commonly used before lateral movement attacks
3. **Targeting sensitive systems** - Enumeration against domain controllers is highly suspicious
4. **Untrusted source** - Queries from workstations to domain controllers are flagged

## Remediation Steps

1. Investigate the source computer for signs of compromise
2. Review the user account that performed the enumeration
3. Check for subsequent lateral movement attempts
4. Verify if the activity was part of legitimate administrative work
5. Consider restricting NetSessionEnum permissions via Group Policy
6. Monitor for credential theft activities on identified sessions

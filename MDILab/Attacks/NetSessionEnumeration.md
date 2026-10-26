# Net Session Enumeration (SMB Session Enumeration)

> **Lab context:** Use `WinClient11` (`10.0.2.51`) in the first forest
> on `LabSubAd1` (`10.0.2.15`, `mayor.mcweeinc.com`).
> Start with `mayor\jsmith`; use `mayor\johna` only for steps requiring
> administrative access. Complete the [scenario setup](README.md#before-running-a-scenario)
> first; membership, sensors, and the example SMB sessions are not preconfigured.

## Overview

Net Session Enumeration is a reconnaissance technique used by attackers to discover active SMB sessions on remote computers within a network. By calling the Windows `NetSessionEnum` API, attackers can identify which users are currently logged into which machines, enabling them to locate high-value targets such as Domain Admins with active sessions and plan lateral movement accordingly.

This technique is commonly used during the discovery phase of an attack. Users and computers access the SYSVOL share to retrieve Group Policy Objects (GPOs), which means domain controllers typically have sessions from many users. Attackers exploit this to map user-to-machine relationships across the network.

Microsoft Defender for Identity (MDI) detects suspicious SMB session enumeration targeting monitored hosts and generates alerts for this reconnaissance activity.

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

The `Invoke-NetSessionEnumeration.ps1` script uses the Windows `NetSessionEnum` API via P/Invoke to retrieve information about established SMB sessions on a target computer.

#### Parameters

| Parameter | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `-ComputerName` | String | No | Local computer | The name of the computer to query for sessions |
| `-ClientName` | String | No | Not set | Filter results to only show sessions from a specific client computer |
| `-UserName` | String | No | Not set | Filter results to only show sessions for a specific user |

#### What the Script Does

1. Defines P/Invoke signatures for the `NetSessionEnum` and `NetApiBufferFree` Windows APIs
2. Defines the `SESSION_INFO_10` structure for marshaling session data
3. Calls `NetSessionEnum` at level 10 to retrieve session information
4. Parses the unmanaged memory buffer into PowerShell objects
5. Returns structured output with computer name, client name, username, active time, and idle time
6. Properly frees the API buffer after use

## Setup

Use the [Invoke-NetSessionEnumeration.ps1](./Invoke-NetSessionEnumeration.ps1) script to enumerate SMB sessions.

### Usage Examples

#### Enumerate sessions on local computer

```powershell
.\Invoke-NetSessionEnumeration.ps1
```

Lists all active SMB sessions on the local computer.

#### Enumerate sessions on a remote server

```powershell
.\Invoke-NetSessionEnumeration.ps1 -ComputerName "LabSubAd1"
```

Lists sessions on `LabSubAd1`, the first-forest controller. Results depend on
actual SMB activity and the caller's permissions; deployment does not seed sessions.

#### Enumerate sessions on multiple domain controllers

```powershell
Get-ADDomainController -Filter * | ForEach-Object {
    .\Invoke-NetSessionEnumeration.ps1 -ComputerName $_.HostName
}
```

Enumerates controllers in the current forest only. It does not automatically
include `LabSubAd2` in the independent `tech.mcweeinc.com` forest.

#### Filter sessions for a specific user

```powershell
.\Invoke-NetSessionEnumeration.ps1 -ComputerName "LabSubAd1" -UserName "johna"
```

Lists only sessions for hydrated user `johna` on `LabSubAd1`, if such sessions exist.

#### Filter sessions from a specific client

```powershell
.\Invoke-NetSessionEnumeration.ps1 -ComputerName "LabSubAd1" -ClientName "WinClient11"
```

Lists sessions originating from `WinClient11`, if any are active.

### Expected Output

Illustrative output after creating the relevant sessions in the selected forest;
these sessions are not automatically created by deployment:

```
ComputerName ClientName    UserName       ActiveTime       IdleTime
------------ ----------    --------       ----------       --------
LabSubAd1    WinClient11   jsmith         00:45:23         00:02:15
LabSubAd1    Win2022       johna          01:23:45         00:00:30
```

#### Error Codes

| Error Code | Meaning |
| -- | -- |
| 5 | Access denied — requires administrative privileges |
| 53 | Network path not found — unable to contact target |
| 2312 | No sessions found on the target computer |

## Scenario Execution

1. Run the script targeting a domain controller to enumerate active sessions
2. Optionally enumerate sessions across multiple domain controllers to simulate a thorough reconnaissance sweep
3. Wait 5–15 minutes for MDI to process the activity
4. Check the Microsoft Security Portal for generated alerts

## Expected Alerts

| Alert Title | Alert Description | Severity | Timeline |
| -- | -- | -- | -- |
| Suspicious Server Message Block (SMB) enumeration from untrusted host | Suspicious SMB session enumeration targeting the MDI sensor | Medium | 5–15 minutes |

| Alert Title | Alert Description | Alert Details |
| -- | -- | -- |
| Suspicious Server Message Block (SMB) enumeration from untrusted host | Suspicious SMB session enumeration targeting the MDI sensor. This indicates adversary reconnaissance aimed at identifying active user sessions on the host. | **Category:** Discovery<br/>**MITRE ATT&CK Techniques:** T1049: System Network Connections Discovery<br/>**Service source:** MDI<br/>**Detection source:** Defender XDR<br/>**Detection technology:** -<br/>**Detection status:** Unknown |

## Why Does This Matter

1. **Reconnaissance indicator** — This technique is commonly used before lateral movement attacks to locate high-value targets
2. **Uncommon behavior** — Most legitimate tools don't enumerate sessions across multiple machines
3. **Targeting sensitive systems** — Enumeration against domain controllers is highly suspicious and indicates an attacker mapping the network
4. **Untrusted source** — Queries from workstations to domain controllers are flagged as unusual
5. **Low privilege requirement** — Session enumeration can sometimes succeed with standard user credentials, making it easy for attackers to execute

## Best Practices

1. Restrict `NetSessionEnum` permissions via Group Policy to limit which accounts can enumerate sessions
2. Monitor SMB traffic patterns for unusual enumeration activity
3. Deploy MDI sensors on all domain controllers to maximize detection coverage
4. Investigate the source computer for signs of compromise when alerts are triggered
5. Review the user account that performed the enumeration for unauthorized access
6. Check for subsequent lateral movement attempts following session enumeration activity

## Clean-Up

This script does not create any accounts, modify group memberships, or write files. No clean-up is required after execution.

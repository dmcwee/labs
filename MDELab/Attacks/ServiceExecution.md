# System Services: Service Execution

## Overview

Service Execution is a technique where attackers abuse the Windows Service Control Manager (services.exe) to run malicious commands or payloads. The Service Control Manager, which allows the management of system services, can be accessed by attackers through both graphical interfaces and command-line utilities like sc.exe and net. This enables them to execute code with service-level privileges, which can aid in establishing persistence or elevating privileges.

## MITRE ATT&CK Mapping

| Tactic | Technique ID | Technique Name |
| --- | --- | --- |
| Execution | T1569.002 | System Services: Service Execution |
| Persistence | T1543.003 | Create or Modify System Process: Windows Service |
| Defense Evasion | T1036.004 | Masquerading: Masquerade Task or Service |

## Expected Alerts

| Alert Title | Alert Description | Alert Details |
| --- | --- | --- |
| Suspicious service registration | A system program was registered as a service. This can indicate malicious intent to establish persistence or gain system privileges. | **Category:** Persistence<br/>**MITRE ATT&CK Techniques:** T1036: Masquerading, T1036.004: Masquerade Task or Service, T1543.003: Windows Service, T1569.002: Service Execution, T1574.011: Services Registry Permissions Weakness<br/>**Service source:** Microsoft Defender for Endpoint<br/>**Detection source:** EDR<br/>**Detection technology:** Behavior<br/>**Detection status:** Detected |

## Attack Simulation

### Prerequisites

- Windows 10/11 or Windows Server test environment
- PowerShell running as **Administrator**
- Microsoft Defender for Endpoint onboarded device

### Script: Invoke-ServiceExecutionSimulation.ps1

#### Parameters

| Parameter | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `Path` | String | No | `$env:TEMP\MaliciousService` | Directory path where service artifacts will be created |
| `CleanUp` | Switch | No | — | Remove the service and all created artifacts |
| `Force` | Switch | No | — | Skip the confirmation prompt before execution |

#### What the Script Does

1. **Creates service folder** — Creates directory at the specified Path
2. **Generates encoded script** — Creates a Base64-encoded PowerShell script that logs activity every 10 minutes
3. **Creates Windows service** — Installs "MaliciousService" with automatic startup type
4. **Starts the service** — Service runs PowerShell with hidden window and encoded command

## Setup

### Usage Examples

```powershell
# Run with default settings
.\Invoke-ServiceExecutionSimulation.ps1

# Run with custom path
.\Invoke-ServiceExecutionSimulation.ps1 -Path "C:\temp\ServiceSim"

# Run with Force to skip confirmation
.\Invoke-ServiceExecutionSimulation.ps1 -Force

# Clean up all artifacts
.\Invoke-ServiceExecutionSimulation.ps1 -CleanUp
```

### Expected Output

```
================================================
                ***  WARNING  *** 
     Service Execution Simulation Script
================================================

This script will perform malicious service activities:
  - Create a hidden PowerShell service
  - Install a Windows service with encoded command
  - Configure service to run automatically
  - Service will execute every 10 minutes

Service files will be created at: C:\Users\...\AppData\Local\Temp\MaliciousService
Service name: MaliciousService

Do you want to continue? (Y/N): Y

Created folder: C:\Users\...\AppData\Local\Temp\MaliciousService
Created encoded service script: C:\...\service-script.txt
Created service: MaliciousService
Service will write to: C:\...\service-log.txt every 10 minutes
Started service: MaliciousService
Check log file at: C:\...\service-log.txt
```

## Scenario Execution

1. Open an elevated PowerShell prompt on the test device.
2. Navigate to the directory containing the script.
3. Run `.\Invoke-ServiceExecutionSimulation.ps1` and confirm with `Y`.
4. The script creates a Windows service that logs activity every 10 minutes.
5. Verify the service is running: `Get-Service -Name MaliciousService`
6. Monitor the Microsoft Defender for Endpoint portal for service-related alerts.
7. After testing, run `.\Invoke-ServiceExecutionSimulation.ps1 -CleanUp` to remove all artifacts.

## Why Does This Matter

Malicious service creation is a powerful technique because:

- **SYSTEM privileges** — Services typically run with the highest local privileges.
- **Persistence** — Services configured for automatic start survive reboots.
- **Stealth** — Services run without user interaction and can be hidden from casual observation.
- **Execution** — Services provide a reliable mechanism to execute arbitrary code.

Detecting malicious service creation is critical for preventing persistence and privilege escalation.

## Best Practices

- **Monitor service creation** — Alert on new service registrations, especially those executing PowerShell or scripts
- **Audit sc.exe and New-Service** — Log all service creation commands
- **Review service binpath** — Alert on services with encoded commands or suspicious executables
- **Implement application whitelisting** — Prevent unauthorized service executables
- **Use Service Control Manager ACLs** — Restrict which accounts can create services
- **Monitor Event ID 7045** — New service installed events in System log

## Clean-Up

Run the script with the `-CleanUp` parameter or manually remove the service:

```powershell
# Using script
.\Invoke-ServiceExecutionSimulation.ps1 -CleanUp

# Manual cleanup
sc.exe stop "MaliciousService"
sc.exe delete "MaliciousService"
Remove-Item -Path "$env:TEMP\MaliciousService" -Recurse -Force
```

## References

- [MITRE ATT&CK T1569.002 - Service Execution](https://attack.mitre.org/techniques/T1569/002/)
- [MITRE ATT&CK T1543.003 - Windows Service](https://attack.mitre.org/techniques/T1543/003/)
- [Microsoft Docs - sc.exe](https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/sc-create)
- [Microsoft Docs - New-Service](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.management/new-service)

## Additional Manual Commands

### Service Execution (Manual Commands)

#### Create and Start Service

```powershell
sc.exe create "MaliciousService" binPath= "%COMSPEC% /c powershell.exe -nop -w hidden -command New-Item -ItemType File C:\art-marker.txt"
sc.exe start "MaliciousService"
```

# Service Creation with Embedded Executable

## Overview

This simulation demonstrates how an attacker can compile malicious C# code directly on a target system and install the resulting executable as a Windows service. By embedding source code within a script and using the .NET compiler present on Windows systems, attackers can create and deploy custom service executables without needing to transfer pre-compiled binaries—evading file-based detection mechanisms that rely on known signatures.

## MITRE ATT&CK Mapping

| Tactic | Technique ID | Technique Name |
| --- | --- | --- |
| Execution | T1569.002 | System Services: Service Execution |
| Persistence | T1543.003 | Create or Modify System Process: Windows Service |
| Defense Evasion | T1027.004 | Obfuscated Files or Information: Compile After Delivery |
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
- .NET Framework installed (typically present by default on Windows)

### Script: Invoke-ServiceWithEmbeddedExeSimulation.ps1

#### Parameters

| Parameter | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `ServiceName` | String | No | `CustomTestService` | The name of the Windows service to create |
| `ServiceDisplayName` | String | No | `Custom Test Service` | The display name shown in the Services console |
| `ExePath` | String | No | `$env:TEMP\CustomTestService.exe` | The file path where the compiled executable will be created |
| `Force` | Switch | No | — | Skip the confirmation prompt before execution |
| `Cleanup` | Switch | No | — | Remove the service, executable, and event log source created by the simulation |

#### What the Script Does

1. **Compiles embedded C# code** — The script contains inline C# source code for a Windows service that writes periodic entries to the Application event log. It uses `Add-Type` to compile this code into a standalone executable.
2. **Creates a Windows service** — Uses `sc.exe create` to register the compiled executable as a demand-start Windows service with the specified name and display name.
3. **Starts the service** — Attempts to start the newly created service and verifies it is running.
4. **Event log activity** — The compiled service writes informational entries to the Application event log under its service name, simulating a persistent background process.

## Setup

### Usage Examples

```powershell
# Run with default settings (creates CustomTestService)
.\Invoke-ServiceWithEmbeddedExeSimulation.ps1

# Run with Force to skip the confirmation prompt
.\Invoke-ServiceWithEmbeddedExeSimulation.ps1 -Force

# Create a service with a custom name and path
.\Invoke-ServiceWithEmbeddedExeSimulation.ps1 -ServiceName "MyTestSvc" -ServiceDisplayName "My Test Service" -ExePath "C:\Temp\MyTestSvc.exe" -Force

# Clean up all resources created by the simulation
.\Invoke-ServiceWithEmbeddedExeSimulation.ps1 -Cleanup

# Clean up a custom-named service
.\Invoke-ServiceWithEmbeddedExeSimulation.ps1 -ServiceName "MyTestSvc" -ExePath "C:\Temp\MyTestSvc.exe" -Cleanup
```

### Expected Output

```
[*] Compiling C# code into executable...
[+] Executable created successfully at: C:\Users\...\AppData\Local\Temp\CustomTestService.exe
[*] Creating Windows service...
[+] Service 'CustomTestService' created successfully!
[*] Service Display Name: Custom Test Service
[*] Service Executable: C:\Users\...\AppData\Local\Temp\CustomTestService.exe

[*] Starting service...
[+] Service started successfully!
[*] Service Status: Running

[*] To check service status, run: Get-Service -Name 'CustomTestService'
[*] To view service logs, check the Application event log
[*] To stop the service, run: Stop-Service -Name 'CustomTestService'
[*] To remove the service, run this script with -Cleanup
```

## Scenario Execution

1. Open an elevated PowerShell prompt on the test device.
2. Navigate to the directory containing the script.
3. Run `.\Invoke-ServiceWithEmbeddedExeSimulation.ps1` and confirm with `Y` when prompted.
4. The script compiles the embedded C# code, creates a Windows service, and starts it.
5. Verify the service is running: `Get-Service -Name 'CustomTestService'`
6. Check the Application event log for entries from the service.
7. Monitor the Microsoft Defender for Endpoint portal for service creation and suspicious executable alerts.
8. After testing, run `.\Invoke-ServiceWithEmbeddedExeSimulation.ps1 -Cleanup` to remove all artifacts.

## Why Does This Matter

The compile-after-delivery technique is significant because:

- **Bypasses signature-based detection** — Since the executable is compiled on the target system, there is no pre-existing binary for antivirus solutions to scan before deployment.
- **Leverages built-in tools** — The .NET compiler is present on most Windows systems, meaning no additional tools need to be downloaded.
- **Establishes persistence** — Windows services run independently of user sessions and can be configured to start automatically, providing a durable persistence mechanism.
- **Elevates privileges** — Services typically run under the SYSTEM account, granting the attacker the highest level of local privilege.
- **Blends with legitimate activity** — Custom services writing to event logs can appear benign to casual observation.

## Best Practices

- Monitor for `Add-Type` usage with `-OutputAssembly` parameters, which indicates dynamic compilation of executables
- Alert on `sc.exe create` commands that register new services, especially with executables in temporary directories
- Implement application whitelisting to prevent execution of binaries from `%TEMP%` and other user-writable locations
- Monitor for new event log sources being registered by unknown processes
- Use Windows Defender Application Control (WDAC) to restrict which binaries can run as services
- Review service creation events (Event ID 7045) in the System event log

## Clean-Up

Run the following command to remove all simulation artifacts:

```powershell
.\Invoke-ServiceWithEmbeddedExeSimulation.ps1 -Cleanup
```

This will:
- Stop the service if it is running
- Delete the Windows service registration
- Remove the compiled executable from disk
- Remove the event log source

## References

- [MITRE ATT&CK T1027.004 - Compile After Delivery](https://attack.mitre.org/techniques/T1027/004/)
- [MITRE ATT&CK T1543.003 - Windows Service](https://attack.mitre.org/techniques/T1543/003/)
- [MITRE ATT&CK T1569.002 - Service Execution](https://attack.mitre.org/techniques/T1569/002/)
- [Microsoft Docs - Add-Type](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/add-type)
- [Microsoft Docs - Windows Service Applications](https://docs.microsoft.com/en-us/dotnet/framework/windows-services/)

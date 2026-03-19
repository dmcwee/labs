# Credential Dumping via Scheduled Tasks

## Overview

This simulation extends the standard credential dumping attack by executing credential extraction techniques through Windows Scheduled Tasks. By leveraging the Task Scheduler, attackers can execute credential dumping operations under the SYSTEM context, evade user-level monitoring, and establish recurring credential harvesting. This approach combines credential access techniques (LSASS dumping, SAM extraction, browser credential theft) with persistence and execution via scheduled tasks, making it harder to detect and attribute.

## MITRE ATT&CK Mapping

| Tactic | Technique ID | Technique Name |
| --- | --- | --- |
| Credential Access | T1003.001 | OS Credential Dumping: LSASS Memory |
| Credential Access | T1003.002 | OS Credential Dumping: Security Account Manager |
| Credential Access | T1555.003 | Credentials from Password Stores: Credentials from Web Browsers |
| Execution | T1053.005 | Scheduled Task/Job: Scheduled Task |
| Persistence | T1053.005 | Scheduled Task/Job: Scheduled Task |
| Defense Evasion | T1140 | Deobfuscate/Decode Files or Information |

## Expected Alerts

| Alert Title | Alert Description | Alert Details |
| --- | --- | --- |
| Suspicious scheduled task activity | A scheduled task was created or modified with characteristics commonly associated with malicious activity. | **Category:** Persistence<br/>**MITRE ATT&CK Techniques:** T1053.005: Scheduled Task<br/>**Service source:** Microsoft Defender for Endpoint<br/>**Detection source:** EDR<br/>**Detection technology:** Behavior<br/>**Detection status:** Detected |
| Possible theft of passwords and other sensitive web browser information | A process might be attempting to retrieve sensitive web browser information, such as saved passwords, cookies, or the browsing history. | **Category:** Credential access<br/>**MITRE ATT&CK Techniques:** T1003: OS Credential Dumping, T1555.003: Credentials from Web Browsers<br/>**Service source:** Microsoft Defender for Endpoint<br/>**Detection source:** EDR<br/>**Detection technology:** Behavior,Network<br/>**Detection status:** Detected |

## Attack Simulation

### Prerequisites

- Windows 10/11 or Windows Server test environment
- PowerShell running as **Administrator**
- Microsoft Defender for Endpoint onboarded device
- Google Chrome and/or Microsoft Edge installed (for browser credential simulation)

### Script: Invoke-CredentialDumpingScheduleSimulation.ps1

#### Parameters

| Parameter | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `OutputPath` | String | No | `$env:TEMP\creddump` | Directory where dumped credential files are saved |
| `CleanUp` | Switch | No | — | Removes all dumped files and scheduled tasks created by the simulation |
| `skipLsass` | Switch | No | — | Skip the LSASS memory dumping simulation |
| `skipSam` | Switch | No | — | Skip the SAM registry hive extraction simulation |
| `skipBrowser` | Switch | No | — | Skip the browser credential dumping simulation |
| `Force` | Switch | No | — | Skip the confirmation prompt before execution |

#### What the Script Does

1. **LSASS Memory Dumping via Scheduled Task** — Creates a base64-encoded PowerShell script that dumps LSASS process memory using `rundll32.exe` and `comsvcs.dll MiniDump`. Registers a scheduled task (`LsassDumpTask`) running as SYSTEM that decodes and executes the script.
2. **SAM Registry Hive Extraction via Scheduled Task** — Creates a scheduled task (`SamDumpTask`) running as SYSTEM that uses `reg.exe save` to extract the SAM, SYSTEM, and SECURITY registry hives.
3. **Browser Credential Theft via Scheduled Task** — Creates a scheduled task (`BrowserDumpTask`) running as the current user that uses `esentutl.exe` to copy Chrome and Edge login databases.
4. Each task is scheduled to trigger once (5 seconds after creation), and the script waits for completion before reporting results.

## Setup

### Usage Examples

```powershell
# Run the full simulation (all three credential dumping techniques)
.\Invoke-CredentialDumpingScheduleSimulation.ps1

# Run with Force to skip the confirmation prompt
.\Invoke-CredentialDumpingScheduleSimulation.ps1 -Force

# Run only the LSASS dump (skip SAM and browser)
.\Invoke-CredentialDumpingScheduleSimulation.ps1 -skipSam -skipBrowser -Force

# Run only the SAM extraction
.\Invoke-CredentialDumpingScheduleSimulation.ps1 -skipLsass -skipBrowser -Force

# Run only browser credential dumping
.\Invoke-CredentialDumpingScheduleSimulation.ps1 -skipLsass -skipSam -Force

# Specify a custom output path
.\Invoke-CredentialDumpingScheduleSimulation.ps1 -OutputPath "C:\Temp\credtest" -Force

# Clean up all simulation artifacts
.\Invoke-CredentialDumpingScheduleSimulation.ps1 -CleanUp
```

### Expected Output

```
Running LSASS Simulation via Scheduled Task
Created base64 encoded script: C:\Users\...\AppData\Local\Temp\creddump\lsass-dump-encoded.txt
[+] Scheduled task 'LsassDumpTask' created successfully!
[*] Task will execute in 5 seconds...
[+] LSASS dump completed successfully!

Running SAM Dumping Simulation via Scheduled Task
[+] Scheduled task 'SamDumpTask' created successfully!
[*] Task will execute in 5 seconds...
[+] SAM dump completed successfully! All 3 hives extracted.

Running BrowserDump Simulation via Scheduled Task
[+] Scheduled task 'BrowserDumpTask' created successfully!
[*] Task will execute in 5 seconds...
[+] Browser dump completed successfully! All 3 databases extracted.
```

## Scenario Execution

1. Open an elevated PowerShell prompt on the test device.
2. Navigate to the directory containing the script.
3. Run `.\Invoke-CredentialDumpingScheduleSimulation.ps1` and type `YES` when prompted to confirm.
4. The script will sequentially create and execute three scheduled tasks that perform credential dumping.
5. Monitor the Microsoft Defender for Endpoint portal for alerts related to credential access and scheduled task creation.
6. After testing, run `.\Invoke-CredentialDumpingScheduleSimulation.ps1 -CleanUp` to remove all artifacts.

## Why Does This Matter

Attackers frequently use scheduled tasks to execute credential dumping operations because:

- **SYSTEM-level execution** — Scheduled tasks can run under the SYSTEM account, granting access to protected resources like LSASS memory and registry hives without needing the attacker's credentials.
- **Defense evasion** — By using base64-encoded scripts and indirect execution through the Task Scheduler, attackers can bypass command-line logging and process monitoring that would catch direct execution.
- **Persistence** — Scheduled tasks can be configured with recurring triggers, enabling automated credential harvesting over time.
- **Reduced forensic footprint** — The actual credential dumping occurs in a separate process context, making attribution more difficult.

## Best Practices

- Monitor scheduled task creation events (Event ID 4698) for tasks executing PowerShell or accessing credential stores
- Alert on `rundll32.exe` loading `comsvcs.dll` with MiniDump parameters
- Monitor `reg.exe save` commands targeting SAM, SYSTEM, and SECURITY hives
- Implement Credential Guard to protect LSASS process memory
- Use LSASS process protection (RunAsPPL) to prevent unauthorized memory access
- Monitor for `esentutl.exe` accessing browser credential databases

## Clean-Up

Run the following command to remove all simulation artifacts:

```powershell
.\Invoke-CredentialDumpingScheduleSimulation.ps1 -CleanUp
```

This will:
- Remove the output directory and all dumped files
- Unregister the `LsassDumpTask` scheduled task
- Unregister the `SamDumpTask` scheduled task
- Unregister the `BrowserDumpTask` scheduled task

## References

- [MITRE ATT&CK T1003.001 - LSASS Memory](https://attack.mitre.org/techniques/T1003/001/)
- [MITRE ATT&CK T1003.002 - Security Account Manager](https://attack.mitre.org/techniques/T1003/002/)
- [MITRE ATT&CK T1053.005 - Scheduled Task](https://attack.mitre.org/techniques/T1053/005/)
- [MITRE ATT&CK T1555.003 - Credentials from Web Browsers](https://attack.mitre.org/techniques/T1555/003/)
- [Microsoft Docs - Credential Guard](https://docs.microsoft.com/en-us/windows/security/identity-protection/credential-guard/)
- [Microsoft Docs - Task Scheduler](https://docs.microsoft.com/en-us/windows/win32/taskschd/task-scheduler-start-page)

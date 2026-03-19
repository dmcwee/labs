# Clear Windows Event Log

## Overview

Clear Windows Event Logs is a technique where attackers delete records in Windows Event Logs to erase evidence of their activities. This action is part of the Defense Evasion tactic, as it helps attackers avoid detection by removing traces of their unauthorized actions from the logs, making it harder for security teams to investigate or respond to the intrusion.

## MITRE ATT&CK Mapping

| Tactic | Technique ID | Technique Name |
| --- | --- | --- |
| Defense Evasion | T1070.001 | Indicator Removal: Clear Windows Event Logs |

## Expected Alerts

| Alert Title | Alert Description | Alert Details |
| --- | --- | --- |
| Event log was cleared | An event log was cleared. This might indicate a malicious actor in the machine. | **Category:** Defense evasion<br/>**MITRE ATT&CK Techniques:** T1070.001: Indicator Removal: Clear Windows Event Logs<br/>**Service source:** Microsoft Defender for Endpoint<br/>**Detection source:** EDR<br/>**Detection technology:** Behavior, Network<br/>**Detection status:** Detected |
| Attempt to clear event log | A process attempted to clear the event log. An attacker might be trying to hide evidence of malicious activity. | **Category:** Defense evasion<br/>**MITRE ATT&CK Techniques:** T1070.001: Indicator Removal: Clear Windows Event Logs<br/>**Service source:** Microsoft Defender for Endpoint<br/>**Detection source:** EDR<br/>**Detection technology:** Behavior, Network<br/>**Detection status:** Detected |

## Attack Simulation

### Prerequisites

- Windows 10/11 or Windows Server test environment
- PowerShell running as **Administrator**
- Microsoft Defender for Endpoint onboarded device

### Script: Invoke-EventLogSimulation.ps1

#### Parameters

| Parameter | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `Mode` | String | No | `powershell` | The method to use for clearing logs. Valid values: `wevtutil` (direct command), `wmic` (via WMI process creation), `powershell` (using Start-Process) |
| `Force` | Switch | No | — | Skip the confirmation prompt before execution |

#### What the Script Does

1. **Clears Application log** — Removes all Application event log entries
2. **Clears System log** — Removes all System event log entries
3. **Clears Security log** — Removes all Security event log entries

> **Warning:** This action cannot be undone. Event logs will be permanently cleared.

## Setup

### Usage Examples

```powershell
# Run with default PowerShell method
.\Invoke-EventLogSimulation.ps1

# Run using direct wevtutil commands
.\Invoke-EventLogSimulation.ps1 -Mode wevtutil

# Run using WMIC process creation
.\Invoke-EventLogSimulation.ps1 -Mode wmic

# Run with Force to skip confirmation
.\Invoke-EventLogSimulation.ps1 -Mode powershell -Force
```

### Expected Output

```
=================================================================
                        ***  WARNING  *** 
            Event Log Clearing Simulation Script
=================================================================

This script will CLEAR SYSTEM EVENT LOGS including:
  - Application logs
  - System logs
  - Security logs

Do you want to continue? (Type 'YES' to proceed): YES

Proceeding with event log clearing simulation...
```

## Scenario Execution

1. Open an elevated PowerShell prompt on the test device.
2. Navigate to the directory containing the script.
3. Run `.\Invoke-EventLogSimulation.ps1 -Mode powershell` (or `wevtutil` or `wmic`).
4. Type `YES` when prompted to confirm.
5. The script clears Application, System, and Security event logs.
6. Monitor the Microsoft Defender for Endpoint portal for defense evasion alerts.

## Why Does This Matter

Event log clearing is a critical anti-forensics technique because:

- **Destroys evidence** — Removes records of attacker commands, login attempts, and malicious activity.
- **Impedes investigation** — Without logs, security teams cannot determine attack timeline or scope.
- **Covers tracks** — Attackers clear logs before exfiltration to hide data theft.
- **Compliance impact** — Log retention is required by many regulatory frameworks.

Detecting log clearing attempts is critical for identifying active attackers trying to cover their tracks.

## Best Practices

- **Forward logs to SIEM** — Send logs to a central repository that cannot be cleared by local administrators
- **Enable log clearing auditing** — Event ID 1102 (Security log cleared) is generated even when the Security log is cleared
- **Alert on log clearing** — Create high-priority alerts for wevtutil cl commands and log clearing events
- **Protect log files** — Use file integrity monitoring on log directories
- **Implement immutable logging** — Use write-once storage for critical security logs
- **Monitor for anti-forensics** — Correlate log clearing with other suspicious activity

## Clean-Up

Event log clearing cannot be undone. Cleared logs are permanently deleted. To verify event logging is functioning:

```powershell
# Generate a test event to verify logging is working
Write-EventLog -LogName Application -Source "Application" -EventId 1000 -Message "Test event after log clearing simulation"

# Verify the event was logged
Get-EventLog -LogName Application -Newest 1
```

## References

- [MITRE ATT&CK T1070.001 - Clear Windows Event Logs](https://attack.mitre.org/techniques/T1070/001/)
- [Microsoft Docs - wevtutil](https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/wevtutil)
- [Microsoft Docs - Windows Event Log](https://docs.microsoft.com/en-us/windows/win32/wes/windows-event-log)

## Additional Manual Commands

### Clear Event Logs (Manual Commands)

#### Direct wevtutil Commands

```powershell
wevtutil cl system
wevtutil cl application
wevtutil cl security
```

#### Using wmic

```powershell
wmic process call create "cmd.exe /c wevtutil cl Application"
wmic process call create "cmd.exe /c wevtutil cl system"
wmic process call create "cmd.exe /c wevtutil cl security"
```

#### Using PowerShell Start-Process

```powershell
Start-Process -FilePath "wevtutil" -ArgumentList "cl", "Application" -NoNewWindow -Wait
Start-Process -FilePath "wevtutil" -ArgumentList "cl", "System" -NoNewWindow -Wait
Start-Process -FilePath "wevtutil" -ArgumentList "cl", "Security" -NoNewWindow -Wait
```

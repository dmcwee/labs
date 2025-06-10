# Clear Windows Event Log

Clear Windows Event Logs is a technique where attackers delete records in Windows Event Logs to erase evidence of their activities. This action is part of the Defense Evasion tactic, as it helps attackers avoid detection by removing traces of their unauthorized actions from the logs, making it harder for security teams to investigate or respond to the intrusion.

## Simulation

Run the following commands in PowerShell as Administrator on a test device.

1. Direct wevtutil Commands
1. Using wmic
1. Using PowerShell Start-Process

### Direct wevtutil Commands

```powershell
wevtutil cl system
wevtutil cl application
wevtutil cl security
```

### Using wmic

```powershell
wmic process call create "cmd.exe /c wevtutil cl Application"
wmic process call create "cmd.exe /c wevtutil cl system"
wmic process call create "cmd.exe /c wevtutil cl security"
```

### Using PowerShell Start-Process

```powershell
Start-Process -FilePath "wevtutil" -ArgumentList "cl", "Application" -NoNewWindow -Wait
Start-Process -FilePath "wevtutil" -ArgumentList "cl", "System" -NoNewWindow -Wait
Start-Process -FilePath "wevtutil" -ArgumentList "cl", "Security" -NoNewWindow -Wait
```

> *Script*: [download](Invoke-EventLogSimulation.ps1)

## Detection

| Alert Title | Alert Description | Alert Details
| --- | --- | --- |
| Event log was cleared | An event log was cleared. This might indicate a malicious actor in the machine. |**Category :** Defense evasion<br/>**MITRE ATT&CK Techniques :** Sub-technique T1070.001<br/>**Service source :** Microsoft Defender for Endpoint<br/>**Detection source :** EDR<br/>**Detection technology :** Behavior,Network<br/>**Detection status :** Detected |
| Attempt to clear event log | A process attempted to clear the event log. An attacker might be trying to hide evidence of malicious activity. |**Category :** Defense evasion<br/>**MITRE ATT&CK Techniques :** Sub-technique T1070.001<br/>**Service source :** Microsoft Defender for Endpoint<br/>**Detection source :** EDR<br/>**Detection technology :** Behavior,Network<br/>**Detection status :** Detected |

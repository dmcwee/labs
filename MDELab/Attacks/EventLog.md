# Clear Windows Event Log

Clear Windows Event Logs is a technique where attackers delete records in Windows Event Logs to erase evidence of their activities. This action is part of the Defense Evasion tactic, as it helps attackers avoid detection by removing traces of their unauthorized actions from the logs, making it harder for security teams to investigate or respond to the intrusion.

## Simulation

Run the following commands in PowerShell as Administrator on a test device.

1. Direct wevtutil Commands
1. Using wmic
1. Using PowerShell Start-Process

---

### Direct wevtutil Commands

```dos
wevtutil cl system
wevtutil cl application
wevtutil cl security
```

---

### Using wmic

```dos
wmic process call create "cmd.exe /c wevtutil cl Application"
wmic process call create "cmd.exe /c wevtutil cl system"
wmic process call create "cmd.exe /c wevtutil cl security"
```

---

### Using PowerShell Start-Process

```powershell
Start-Process -FilePath "wevtutil" -ArgumentList "cl", "Application" -NoNewWindow -Wait
Start-Process -FilePath "wevtutil" -ArgumentList "cl", "System" -NoNewWindow -Wait
Start-Process -FilePath "wevtutil" -ArgumentList "cl", "Security" -NoNewWindow -Wait
```

> *Script*: [download](Clear-EventLog.ps1)

## Detection

| Alert title | Event log was cleared |
| Alert description | An event log was cleared. This might indicate a malicious actor in the machine. |
| Alert details |
Category : Defense evasion
MITRE ATT&CK Techniques : Sub-technique T1070.001
Service source : Microsoft Defender for Endpoint 
Detection source : EDR 
Detection technology : Behavior,Network
Detection status : Detected |


| Alert title | Attempt to clear event log |
| Alert description | A process attempted to clear the event log. An attacker might be trying to hide evidence of malicious activity. |
| Alert details |
Category : Defense evasion
MITRE ATT&CK Techniques : Sub-technique T1070.001
Service source : Microsoft Defender for Endpoint 
Detection source : EDR 
Detection technology : Behavior,Network
Detection status : Detected |

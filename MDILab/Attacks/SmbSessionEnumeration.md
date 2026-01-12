# SMB Session Enumeration (Net Session Enumeration)

In this detection, an alert is triggered when an SMB session enumeration is performed against a domain controller.

Users and computers need to at least access the SYSVOL share to retrieve GPOs. Attackers can use this information to know where users recently signed in and move laterally in the network to get to a specific sensitive account.

## Simulation

Download and the [Invoke-NetSessionEnumeration.ps1 script](./Invoke-NetSessionEnumeration.ps1).

Lists all sessions on SERVER01.

```powershell
    .\Invoke-NetSessionEnumeration.ps1 -ComputerName "SERVER01"
```
    
Lists all sessions for user 'john' on SERVER01.

```powershell
    .\Invoke-NetSessionEnumeration.ps1 -ComputerName "SERVER01" -UserName "john"
```


## Detections

| Alert Title | Alert Description | Alert Details |
| -- | -- | -- |
| xxx| xxx | **Category:** xxx<br/>**MITRE ATT&CK Techniques:** xxx<br/>**Service source:** xxx<br/>**Detection source:** xxx<br/>**Detection technology:** xxx<br/>**Detection status:** xxx |

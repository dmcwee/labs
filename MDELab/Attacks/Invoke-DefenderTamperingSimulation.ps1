param(
    [switch]$cleanup,
    [switch]$Force
)

# Warning prompt
if (!$cleanup -and !$Force) {
    Write-Host "`n==================================================================" -ForegroundColor Yellow
    Write-Host "                        ***  WARNING  *** " -ForegroundColor Red
    Write-Host "           Defender Tampering Simulation Script" -ForegroundColor Yellow
    Write-Host "==================================================================" -ForegroundColor Yellow
    Write-Host "`nThis script performs Defender tampering actions that will:" -ForegroundColor Yellow
    Write-Host "  - Disable real-time monitoring" -ForegroundColor Red
    Write-Host "  - Disable MAPS reporting" -ForegroundColor Red
    Write-Host "  - Add broad exclusions to Defender" -ForegroundColor Red
    Write-Host "`nThese actions may trigger Microsoft Defender for Endpoint to:" -ForegroundColor Yellow
    Write-Host "  - Flag this device as compromised" -ForegroundColor Magenta
    Write-Host "  - ISOLATE THE DEVICE from the network" -ForegroundColor Magenta
    Write-Host "  - Generate high-severity security alerts" -ForegroundColor Magenta
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
    
    Write-Host "`nProceeding with Defender tampering simulation..." -ForegroundColor Yellow
    Start-Sleep -Seconds 2
}

if(!$cleanup) {
    Set-MpPreference -DisableRealtimeMonitoring $true
    Set-MpPreference -MAPSReporting 0
    Set-MpPreference -ExclusionExtension "exe" -ExclusionPath "C:\"
}
else {
    Set-MpPreference -DisableRealtimeMonitoring $false
    Set-MpPreference -MAPSReporting 2
    Remove-MpPreference -ExclusionExtension "exe" -ExclusionPath "C:\"
}
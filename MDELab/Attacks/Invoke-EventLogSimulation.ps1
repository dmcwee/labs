param(
    [string][ValidateSet("wevtutil", "wmic", "powershell")]$Mode,
    [switch]$Force
)

# Warning prompt
if (!$Force) {
    Write-Host "`n==================================================================" -ForegroundColor Yellow
    Write-Host "                        ***  WARNING  *** " -ForegroundColor Red
    Write-Host "            Event Log Clearing Simulation Script" -ForegroundColor Yellow
    Write-Host "==================================================================" -ForegroundColor Yellow
    Write-Host "`nThis script will CLEAR SYSTEM EVENT LOGS including:" -ForegroundColor Yellow
    Write-Host "  - Application logs" -ForegroundColor Red
    Write-Host "  - System logs" -ForegroundColor Red
    Write-Host "  - Security logs" -ForegroundColor Red
    Write-Host "`nThis action:" -ForegroundColor Yellow
    Write-Host "  - Destroys forensic evidence and audit trails" -ForegroundColor Magenta
    Write-Host "  - May trigger Microsoft Defender for Endpoint alerts" -ForegroundColor Magenta
    Write-Host "  - Could result in DEVICE ISOLATION" -ForegroundColor Magenta
    Write-Host "  - Is commonly used by attackers to cover their tracks" -ForegroundColor Magenta
    Write-Host "`nYour account may be subject to investigation and remediation." -ForegroundColor Yellow
    Write-Host "Event logs CANNOT be recovered after clearing." -ForegroundColor Red
    Write-Host "  - This should only be run on an approved testing machine." -ForegroundColor Red
    Write-Host "==================================================================" -ForegroundColor Yellow
    Write-Host "`nUse -Force parameter to skip this prompt." -ForegroundColor Gray
    Write-Host "`n"
    
    $confirmation = Read-Host "Do you want to continue? (Type 'YES' to proceed)"
    
    if ($confirmation -ne "YES") {
        Write-Host "`nOperation cancelled by user. No logs were cleared." -ForegroundColor Green
        exit
    }
    
    Write-Host "`nProceeding with event log clearing simulation..." -ForegroundColor Yellow
    Start-Sleep -Seconds 2
}

if($Mode -eq "webtutil") {
    wevtutil cl system
    wevtutil cl application
    wevtutil cl security
}
elseif ($Mode -eq "wmic") {
    wmic process call create "cmd.exe /c wevtutil cl Application"
    wmic process call create "cmd.exe /c wevtutil cl system"
    wmic process call create "cmd.exe /c wevtutil cl security"
}
else {
    Start-Process -FilePath "wevtutil" -ArgumentList "cl", "Application" -NoNewWindow -Wait
    Start-Process -FilePath "wevtutil" -ArgumentList "cl", "System" -NoNewWindow -Wait
    Start-Process -FilePath "wevtutil" -ArgumentList "cl", "Security" -NoNewWindow -Wait
}

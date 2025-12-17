param(
    [string]$Path = "$env:TEMP\MaliciousService",
    [switch]$CleanUp,
    [switch]$Force
)

# Display warning prompt unless Force is specified or in CleanUp mode
if (-not $Force -and -not $CleanUp) {
    Write-Host "`n================================================" -ForegroundColor Yellow
    Write-Host "                ***  WARNING  *** " -ForegroundColor Red
    Write-Host "     Service Execution Simulation Script" -ForegroundColor Yellow
    Write-Host "================================================" -ForegroundColor Yellow
    Write-Host "`nThis script will perform malicious service activities:" -ForegroundColor White
    Write-Host "  - Create a hidden PowerShell service" -ForegroundColor Cyan
    Write-Host "  - Install a Windows service with encoded command" -ForegroundColor Cyan
    Write-Host "  - Configure service to run automatically" -ForegroundColor Cyan
    Write-Host "  - Service will execute every 10 minutes" -ForegroundColor Cyan
    Write-Host "`nService files will be created at: $Path" -ForegroundColor White
    Write-Host "Service name: MaliciousService" -ForegroundColor White
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

if($CleanUp) {
    # Stop the service first if it's running
    $service = Get-Service -Name "MaliciousService" -ErrorAction SilentlyContinue
    if ($service) {
        if ($service.Status -eq 'Running') {
            Stop-Service -Name "MaliciousService" -Force -ErrorAction SilentlyContinue
            Write-Host "Stopped service: MaliciousService" -ForegroundColor Yellow
            Start-Sleep -Seconds 2  # Give it time to stop
        }
        
        # Remove the service using CIM cmdlet
        Get-CimInstance -ClassName Win32_Service -Filter "Name='MaliciousService'" | Remove-CimInstance
        Write-Host "Deleted service: MaliciousService" -ForegroundColor Green
    }
    else {
        Write-Host "Service 'MaliciousService' not found (may already be deleted)" -ForegroundColor Gray
    }
    
    # Remove all created files and folders
    if(Test-Path -Path $Path) {
        Remove-Item -Path $Path -Recurse -Force
        Write-Host "Deleted folder and all contents: $Path" -ForegroundColor Green
        Write-Host "  - Removed: service-script.txt (encoded script)" -ForegroundColor Gray
        Write-Host "  - Removed: service-log.txt (log file)" -ForegroundColor Gray
    }
    else {
        Write-Host "Folder not found: $Path (may already be deleted)" -ForegroundColor Gray
    }
}
else {
    if(-not (Test-Path -Path $Path)) {
        New-Item -Path $Path -ItemType Directory -ErrorAction SilentlyContinue
        Write-Host "Created folder: $Path" -ForegroundColor Green
    }

    # Create the PowerShell script that will run every 10 minutes
    $encodedScriptPath = "$Path\service-script.txt"
    $logFile = "$Path\service-log.txt"
    
    $scriptContent = @"
# Service script that runs continuously and writes to log every 10 minutes
`$logFile = "$logFile"

while (`$true) {
    `$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    `$message = "[`$timestamp] Service execution marker - Process ID: `$PID"
    Add-Content -Path `$logFile -Value `$message -Force
    Write-Host `$message
    
    # Wait for 10 minutes (600 seconds)
    Start-Sleep -Seconds 600
}
"@
    
    # Base64 encode the script content
    $bytes = [System.Text.Encoding]::Unicode.GetBytes($scriptContent)
    $encodedScript = [Convert]::ToBase64String($bytes)
    
    # Save the encoded script to a file
    Set-Content -Path $encodedScriptPath -Value $encodedScript -Force
    Write-Host "Created encoded service script: $encodedScriptPath" -ForegroundColor Green

    # Create the service with PowerShell command that decodes and executes the script
    # The service reads the base64 encoded file, decodes it, and executes the content
    $decoderCommand = "`$encoded = Get-Content -Path '$encodedScriptPath' -Raw; `$decoded = [System.Text.Encoding]::Unicode.GetString([Convert]::FromBase64String(`$encoded)); Invoke-Expression `$decoded"
    $binPath = "powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -EncodedCommand $([Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($decoderCommand)))"
    
    # Create the service using New-Service cmdlet
    New-Service -Name "MaliciousService" -BinaryPathName $binPath -DisplayName "MaliciousService" -StartupType Automatic -Description "Simulated malicious service for MDE Lab"
    Write-Host "Created service: MaliciousService" -ForegroundColor Green
    Write-Host "Service will write to: $logFile every 10 minutes" -ForegroundColor Yellow

    # Start the service
    Start-Service -Name "MaliciousService"
    Write-Host "Started service: MaliciousService" -ForegroundColor Green
    Write-Host "Check log file at: $logFile" -ForegroundColor Cyan
}
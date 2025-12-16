<#
.SYNOPSIS
    Creates an executable from embedded C# code and installs it as a Windows service.

.DESCRIPTION
    This script compiles C# code into an executable and creates a Windows service to run it.
    The service is a simple example that writes to the event log periodically.

.PARAMETER ServiceName
    The name of the Windows service to create.

.PARAMETER ServiceDisplayName
    The display name of the Windows service.

.PARAMETER ExePath
    The path where the executable will be created.

.PARAMETER Cleanup
    If specified, the script will clean up all created resources (service, executable, event log source) after execution.

.EXAMPLE
    .\New-ServiceWithEmbeddedExe.ps1 -ServiceName "TestService" -ServiceDisplayName "Test Service" -ExePath "C:\Temp\TestService.exe"

.EXAMPLE
    .\New-ServiceWithEmbeddedExe.ps1 -ServiceName "TestService" -Cleanup
    Creates and then cleans up the service and all generated files.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$ServiceName = "CustomTestService",
    
    [Parameter(Mandatory = $false)]
    [string]$ServiceDisplayName = "Custom Test Service",
    
    [Parameter(Mandatory = $false)]
    [string]$ExePath = "$env:TEMP\CustomTestService.exe",
    
    [Parameter(Mandatory = $false)]
    [switch]$Force,
    
    [Parameter(Mandatory = $false)]
    [switch]$Cleanup
)

# Display warning prompt unless Force is specified
if (-not $Force -and -not $Cleanup) {
    Write-Host "`n================================================" -ForegroundColor Yellow
    Write-Host "                ***  WARNING  *** " -ForegroundColor Red
    Write-Host "   Service Creation with Embedded Exe Script" -ForegroundColor Yellow
    Write-Host "================================================" -ForegroundColor Yellow
    Write-Host "`nThis script will create and install a Windows service:" -ForegroundColor White
    Write-Host "  - Compile C# code into an executable" -ForegroundColor Cyan
    Write-Host "  - Create service: $ServiceName" -ForegroundColor Cyan
    Write-Host "  - Display name: $ServiceDisplayName" -ForegroundColor Cyan
    Write-Host "  - Executable path: $ExePath" -ForegroundColor Cyan
    Write-Host "  - Service will write to Application event log" -ForegroundColor Cyan
    Write-Host "`nThis is for TESTING/SIMULATION purposes only." -ForegroundColor Red
    Write-Host "This activity may trigger security alerts." -ForegroundColor Red
    Write-Host "================================================`n" -ForegroundColor Yellow
    
    $response = Read-Host "Do you want to continue? (Y/N)"
    if ($response -notmatch '^[Yy]') {
        Write-Host "Script execution cancelled by user." -ForegroundColor Yellow
        return
    }
    Write-Host ""
}

# Cleanup section
if ($Cleanup) {
    Write-Host "`n[*] Starting cleanup process..." -ForegroundColor Cyan
    
    # Stop and remove the service
    $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    if ($service) {
        Write-Host "[*] Removing service '$ServiceName'..." -ForegroundColor Cyan
        
        if ($service.Status -eq 'Running') {
            Write-Host "    - Stopping service..." -ForegroundColor Yellow
            Stop-Service -Name $ServiceName -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 2
        }
        
        sc.exe delete $ServiceName | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[+] Service removed successfully" -ForegroundColor Green
        }
        else {
            Write-Host "[-] Failed to remove service (exit code: $LASTEXITCODE)" -ForegroundColor Red
        }
        Start-Sleep -Seconds 1
    }
    else {
        Write-Host "[*] Service '$ServiceName' not found (may have already been removed)" -ForegroundColor Yellow
    }
    
    # Remove the executable file
    if (Test-Path -Path $ExePath) {
        Write-Host "[*] Removing executable: $ExePath..." -ForegroundColor Cyan
        try {
            Remove-Item -Path $ExePath -Force -ErrorAction Stop
            Write-Host "[+] Executable removed successfully" -ForegroundColor Green
        }
        catch {
            Write-Host "[-] Failed to remove executable: $_" -ForegroundColor Red
        }
    }
    else {
        Write-Host "[*] Executable not found at: $ExePath" -ForegroundColor Yellow
    }
    
    # Remove event log source
    if ([System.Diagnostics.EventLog]::SourceExists($ServiceName)) {
        Write-Host "[*] Removing event log source '$ServiceName'..." -ForegroundColor Cyan
        try {
            [System.Diagnostics.EventLog]::DeleteEventSource($ServiceName)
            Write-Host "[+] Event log source removed successfully" -ForegroundColor Green
        }
        catch {
            Write-Host "[-] Failed to remove event log source: $_" -ForegroundColor Red
            Write-Host "    Note: You may need to restart the system for complete removal" -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "[*] Event log source '$ServiceName' not found" -ForegroundColor Yellow
    }
    
    Write-Host "`n[+] Cleanup process completed!" -ForegroundColor Green
}
else {

    # Embedded C# code for a Windows service
    $csharpCode = @"
using System;
using System.Diagnostics;
using System.ServiceProcess;
using System.Threading;

namespace CustomServiceNamespace
{
    public class CustomService : ServiceBase
    {
        private Thread workerThread;
        private bool isRunning = false;
        private EventLog eventLog;

        public CustomService()
        {
            this.ServiceName = "$ServiceName";
            this.CanStop = true;
            this.CanPauseAndContinue = false;
            this.AutoLog = true;

            // Create event log source
            if (!EventLog.SourceExists(this.ServiceName))
            {
                EventLog.CreateEventSource(this.ServiceName, "Application");
            }
            eventLog = new EventLog();
            eventLog.Source = this.ServiceName;
        }

        protected override void OnStart(string[] args)
        {
            eventLog.WriteEntry("Service starting...", EventLogEntryType.Information);
            isRunning = true;
            workerThread = new Thread(WorkerMethod);
            workerThread.Start();
        }

        protected override void OnStop()
        {
            eventLog.WriteEntry("Service stopping...", EventLogEntryType.Information);
            isRunning = false;
            if (workerThread != null && workerThread.IsAlive)
            {
                workerThread.Join(5000); // Wait up to 5 seconds for thread to finish
            }
        }

        private void WorkerMethod()
        {
            int counter = 0;
            while (isRunning)
            {
                counter++;
                eventLog.WriteEntry(
                    string.Format("Service is running. Iteration: {0}", counter),
                    EventLogEntryType.Information);
                
                Thread.Sleep(600000); // Sleep for 10 minutes
            }
        }

        static void Main(string[] args)
        {
            ServiceBase.Run(new CustomService());
        }
    }
}
"@

    Write-Host "[*] Compiling C# code into executable..." -ForegroundColor Cyan

    try {
        # Ensure the output directory exists
        $outputDir = Split-Path -Path $ExePath -Parent
        if (-not (Test-Path -Path $outputDir)) {
            New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
        }

        # Add required assemblies
        Add-Type -TypeDefinition $csharpCode `
            -ReferencedAssemblies @(
            "System.dll",
            "System.ServiceProcess.dll",
            "System.Configuration.Install.dll"
        ) `
            -OutputAssembly $ExePath `
            -OutputType ConsoleApplication

        Write-Host "[+] Executable created successfully at: $ExePath" -ForegroundColor Green

        # Check if service already exists
        $existingService = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
        if ($existingService) {
            Write-Host "[!] Service '$ServiceName' already exists. Removing it..." -ForegroundColor Yellow
        
            # Stop the service if it's running
            if ($existingService.Status -eq 'Running') {
                Stop-Service -Name $ServiceName -Force
                Start-Sleep -Seconds 2
            }
        
            # Remove the service
            sc.exe delete $ServiceName | Out-Null
            Start-Sleep -Seconds 2
        }

        # Create the Windows service
        Write-Host "[*] Creating Windows service..." -ForegroundColor Cyan
    
        $createServiceResult = sc.exe create $ServiceName binPath= $ExePath start= demand DisplayName= $ServiceDisplayName
    
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[+] Service '$ServiceName' created successfully!" -ForegroundColor Green
            Write-Host "[*] Service Display Name: $ServiceDisplayName" -ForegroundColor Cyan
            Write-Host "[*] Service Executable: $ExePath" -ForegroundColor Cyan
            Write-Host ""
            
            # Start the service
            Write-Host "[*] Starting service..." -ForegroundColor Cyan
            try {
                Start-Service -Name $ServiceName -ErrorAction Stop
                Start-Sleep -Seconds 2
                
                $serviceStatus = Get-Service -Name $ServiceName
                if ($serviceStatus.Status -eq 'Running') {
                    Write-Host "[+] Service started successfully!" -ForegroundColor Green
                    Write-Host "[*] Service Status: Running" -ForegroundColor Green
                }
                else {
                    Write-Host "[!] Service created but status is: $($serviceStatus.Status)" -ForegroundColor Yellow
                }
            }
            catch {
                Write-Host "[-] Failed to start service: $_" -ForegroundColor Red
                Write-Host "[*] You may need to start it manually with: Start-Service -Name '$ServiceName'" -ForegroundColor Yellow
            }
            
            Write-Host ""
            Write-Host "[*] To check service status, run: Get-Service -Name '$ServiceName'" -ForegroundColor Yellow
            Write-Host "[*] To view service logs, check the Application event log" -ForegroundColor Yellow
            Write-Host "[*] To stop the service, run: Stop-Service -Name '$ServiceName'" -ForegroundColor Yellow
            Write-Host "[*] To remove the service, run this script with -Cleanup" -ForegroundColor Yellow
        }
        else {
            Write-Host "[-] Failed to create service. Error code: $LASTEXITCODE" -ForegroundColor Red
            Write-Host $createServiceResult
        }
    }
    catch {
        Write-Host "[-] Error occurred: $_" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }

}
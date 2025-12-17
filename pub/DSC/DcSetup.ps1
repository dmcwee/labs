param(
	[string]$DomainName,
	[string]$NetBiosName,
	[string]$Password,
    [string]$HydrationScript = "DcHydrate.ps1"
)

function Write-Log {
    param (
        [string]$message,
        [string]$source,
        [string]$entryType = "Information", # Entry type: Information, Warning, or Error
        $eventID = 1001
    )
    $logName = "Application"   # The event log to write to

    # Create the source if it doesn't exist
    if (-not [System.Diagnostics.EventLog]::SourceExists($source)) {
        New-EventLog -LogName $logName -Source $source
    }

    # Write to the event log
    Write-EventLog -LogName $logName -Source $source -EventId $eventID -EntryType $entryType -Message $message  
}

try {
    $taskName = "Hydrate-DC"

    # Prep domain hydration folder and script
    $hydrationFolder = "c:\hydration"
    $script = "$hydrationFolder\$HydrationScript"
    New-Item -Path $hydrationFolder -ItemType Directory -ErrorAction SilentlyContinue
    Copy-Item -Path ".\$HydrationScript" -Destination $script -ErrorAction Stop
    Write-Log -message "Copied $HydrationScript to $script." -source $taskName -eventID 1000

    # Create Run Once Registry Key
    $registryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce"
    $command = "powershell.exe -ExecutionPolicy Bypass -File ""$script"" -password $Password -TaskName $taskName"
    $logCommand = $command.Replace($Password, "xxxxx")
    New-ItemProperty -Path $registryPath -Name $taskName -Value $command -PropertyType String
    Write-Log -message $("RunOnce Command: $logCommand has been created") -source $taskName -eventID 1001

    # Install AD DS and RSAT tools
    Install-WindowsFeature -Name AD-Domain-Services, RSAT-AD-Tools -IncludeManagementTools
    Write-Log -message "Active Directory features have been installed." -source $taskName -eventID 1002

    # Import ADDSDeployment module
    Import-Module ADDSDeployment

    $SecurePassword = ConvertTo-SecureString -String $Password -AsPlainText -Force

    # Install new forest and domain controller
    Install-ADDSForest `
        -DomainName $DomainName `
        -DomainNetbiosName $NetBiosName `
        -SafeModeAdministratorPassword $SecurePassword `
        -InstallDNS `
        -Force

    Write-Log -message "Active Directory Domain Services and new domain '$DomainName' have been installed." -source $taskName -eventID 1003
}
catch {
    Write-Log -message "ERROR: $_" -source $taskName -entryType "Error" -eventID 1999
}
param(
    [string]$Password,
    [string]$TaskName
)

# Entry type: Information, Warning, or Error
function Write-Log {
    param (
        [string]$message,
        [string]$source,
        [string]$entryType = "Information", # Entry type: Information, Warning, or Error
        $eventID = 2000
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
# Import Active Directory module
Import-Module ActiveDirectory
Write-Log -message "Module ActiveDirectory loaded" -source $TaskName -eventID 2000

# Set OU and domain variables
$ouName = "LabUsers"
$domain = (Get-ADDomain).DistinguishedName
$ouPath = "OU=$ouName,$domain"
Write-Log -message $("OU Path: $ouPath") -source $TaskName -eventID 2001

$securePassword = ConvertTo-SecureString -String $password -AsPlainText -Force

# Create the OU if it doesn't exist
if (-not (Get-ADOrganizationalUnit -Filter "Name -eq '$ouName'" -ErrorAction SilentlyContinue)) {
    Write-Log -message $("OU '$ouName' does not exist. Creating OU.") -source $TaskName -eventID 2002
    New-ADOrganizationalUnit -Name $ouName -Path $domain -ErrorAction Stop
    Write-Log -message $("OU '$ouName' created.") -source $TaskName -eventID 2003
}
else {
    Write-Log -message $("OU $ouName exists, but shouldn't!") -source $TaskName -eventID 0200
}

# Create users in the LabUsers OU
Write-Log -message "Creating User Accounts." -source $TaskName -eventID 2004
New-ADUser -Name "John Smith" -SamAccountName "jsmith" -AccountPassword $securePassword -Enabled $true -Path $ouPath -ErrorAction Stop
New-ADUser -Name "Ron HelpDesk" -SamAccountName "ronhd" -AccountPassword $securePassword -Enabled $true -Path $ouPath -ErrorAction Stop
New-ADUser -Name "John Admin" -SamAccountName "johna" -AccountPassword $securePassword -Enabled $true -Path $ouPath -ErrorAction Stop
Write-Log -message "User Accounts Created." -source $TaskName -eventID 2005

# Create helpdesk group in the LabUsers OU
New-ADGroup -Name "helpdesk" -GroupScope Global -Path $ouPath
Write-Log -message "helpdesk group created." -source $TaskName -eventID 2006

# Add John Admin to Domain Admins group
Add-ADGroupMember -Identity "Domain Admins" -Members "johna"
Write-Log -message "John Admin added to Domain Admins." -source $TaskName -eventID 2007

# Add Ron HelpDesk to helpdesk group
Add-AdGroupMember -Identity "helpdesk" -Members "ronhd"
Write-log -message "Ron added to helpdesk group" -source $TaskName -eventID 2008

Write-Log -message "OU, users, group, and group membership have been created. DcHyrate Script Completed." -source $TaskName -eventID 2008
}
catch {
    Write-Log -message $("ERROR: $_") -source $TaskName -eventID 2999 -entryType "Error"
}
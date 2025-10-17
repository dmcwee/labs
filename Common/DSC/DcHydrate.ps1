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
    Import-Module ActiveDirectory
    Write-Log -message "Module ActiveDirectory loaded" -source $TaskName -eventID 2000

    # Set OU and domain variables
    $ouName = "LabUsers"
    $domain = (Get-ADDomain).DistinguishedName
    $domainRoot = (Get-ADDomain).DNSRoot
    $ouPath = "OU=$ouName,$domain"
    Write-Log -message $("OU Path: $ouPath") -source $TaskName -eventID 2100
    Write-Log -message $("DNS Root: $domainRoot") -source $TaskName -eventID 2101

    $securePassword = ConvertTo-SecureString -String $password -AsPlainText -Force

    # Create the OU if it doesn't exist
    if (-not (Get-ADOrganizationalUnit -Filter "Name -eq '$ouName'" -ErrorAction SilentlyContinue)) {
        Write-Log -message $("OU '$ouName' does not exist. Creating OU.") -source $TaskName -eventID 2200
        New-ADOrganizationalUnit -Name $ouName -Path $domain -ErrorAction Stop
        Write-Log -message $("OU '$ouName' created.") -source $TaskName -eventID 2201
    }
    else {
        Write-Log -message $("OU $ouName exists, but shouldn't!") -source $TaskName -eventID 2299
    }

    # Create users in the LabUsers OU using an array and loop
    Write-Log -message "Creating User Accounts." -source $TaskName -eventID 2300
    $users = @(
        @{ Name = "John Smith"; AccountName = "jsmith"; Groups = @() },
        @{ Name = "Ron HelpDesk"; AccountName = "ronhd"; Groups = @("Helpdesk") },
        @{ Name = "John Admin"; AccountName = "johna"; Groups = @("Domain Admins") }
    )
    $commonParams = @{
        AccountPassword      = $securePassword
        Path                 = $ouPath
        Enabled              = $true
        CannotChangePassword = $true
        PasswordNeverExpires = $true
        ErrorAction          = "Stop"
    }

    foreach ($user in $users) {
        $upn = "$($user.AccountName)@$domainRoot"
        New-ADUser -Name $user.Name -SamAccountName $user.AccountName -UserPrincipalName $upn @commonParams
        $eventID = 2300 + [array]::IndexOf($users, $user)
        Write-Log -message "User Account $($user.Name) Created." -source $TaskName -eventID $eventID
    }
    Write-Log -message "User Account Creation Completed." -source $TaskName -eventID 2399

    Write-Log -message "Group Setup Beginning" -source $TaskName -eventID 2400

    # Check if Helpdesk group exists in the LabUsers OU, create if not
    $helpdeskGroup = Get-ADGroup -Filter { Name -eq "Helpdesk" -and DistinguishedName -like "*${ouName}*" } -SearchBase $ouPath -ErrorAction SilentlyContinue
    if (-not $helpdeskGroup) {
        New-ADGroup -Name "Helpdesk" -GroupScope Global -Path $ouPath
        Write-Log -message "Helpdesk group created." -source $TaskName -eventID 2401
    }
    else {
        Write-Log -message "Helpdesk group already exists in $ouPath." -source $TaskName -eventID 2489
    }

    # Add John Admin to Domain Admins group
    Add-ADGroupMember -Identity "Domain Admins" -Members "johna"
    Write-Log -message "John Admin added to Domain Admins." -source $TaskName -eventID 2402

    # Add Ron HelpDesk to helpdesk group
    Add-AdGroupMember -Identity "helpdesk" -Members "ronhd"
    Write-log -message "Ron added to helpdesk group" -source $TaskName -eventID 2403

    Write-Log -message "OU, users, group, and group membership have been created. DcHyrate Script Completed." -source $TaskName -eventID 2404
}
catch {
    Write-Log -message $("ERROR: $_") -source $TaskName -eventID 2499 -entryType "Error"
}
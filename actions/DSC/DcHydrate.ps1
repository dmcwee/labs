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

function Get-GuaranteedGroup {
    param(
        [string]$GroupName,
        [string]$GroupOuPath
    )

    Write-Log -message "Get-GuaranteedGroup $GroupName in $GroupOuPath" -source $TaskName -eventID 3000

    $group = Get-ADGroup -Filter "Name -eq '$GroupName'" -ErrorAction SilentlyContinue
    if($group) { 
        Write-Log -message "Group $GroupName already exists. Returning $GroupName" -source $TaskName -eventID 3001
        return $group 
    }
    else {
        Write-Log -message "Group $GroupName does not exists. Creating $GroupName in $GroupOuPath" -source $TaskName -eventID 3100
        $newGroupParams = @{
            Name           = $GroupName
            SamAccountName = $GroupName
            GroupScope     = 'Global'
            GroupCategory  = 'Security'
            Path           = $GroupOuPath
            ErrorAction    = "Stop"
        }
        try {
            $group = New-ADGroup @newGroupParams -PassThru
            Write-Log -message "Group $GroupName created in $GroupOuPath" -source $TaskName -eventID 3101
            return $group
        }
        catch {
            Write-Log -message "Attempt to create group $GroupName failed: $($_.Exception.Message)" -source $TaskName -eventID 3199 -entryType "Error"
        }
    }
    return $null
}

function Get-GuaranteedUser {
    param(
        [string]$Name,
        [string]$AccountName,
        [string]$UPN,
        [securestring]$AccountPassword,
        [string]$UserOuPath
    )

    Write-Log -message "Get-GuaranteedUser $Name in $UserOuPath" -source $TaskName -eventID 4000

    $user = Get-ADUser -Filter "SamAccountName -eq '$AccountName'" -ErrorAction SilentlyContinue
    if($user) {
        Write-Log -message "User $Name already exists. Returning $Name ($AccountName)" -source $TaskName -eventID 4001
        return $user
    }
    else {
        Write-Log -message "User $Name does not exists. Creating User $Name ($AccountName) in $UserOuPath" -source $TaskName -eventID 4100
        $userParams = @{
            Name                 = $Name
            SamAccountName       = $AccountName
            DisplayName          = $Name
            UserPrincipalName    = $UPN
            AccountPassword      = $AccountPassword
            Path                 = $UserOuPath
            Enabled              = $true
            CannotChangePassword = $true
            PasswordNeverExpires = $true
            ErrorAction          = "Stop"
        }

        try {
            $user = New-ADUser @userParams -PassThru
            Write-Log -message "User $Name created in $UserOuPath" -source $TaskName -eventID 4101
            return $user
        }
        catch {
            Write-Log -message "Attempt to create user $Name failed: $($_.Exception.Message)" -source $TaskName -eventID 4199 -entryType "Error"
        }
    }
    return $null
}

try {
    Import-Module ActiveDirectory
    Write-Log -message "Module ActiveDirectory loaded" -source $TaskName -eventID 2000

    # Set OU and domain variables
    $ouName = "LabUsers"
    $ouPath = "OU=$ouName,$((Get-ADDomain).DistinguishedName)"
    Write-Log -message $("OU Path: $ouPath") -source $TaskName -eventID 2100

    $domainRoot = (Get-ADDomain).DNSRoot
    Write-Log -message $("DNS Root: $domainRoot") -source $TaskName -eventID 2101

    Add-KdsRootKey -EffectiveTime ((Get-Date).addhours(-10))
    Write-Log -message "KDS Root Key added" -source $TaskName -eventID 2102

    $securePassword = ConvertTo-SecureString -String $password -AsPlainText -Force

    # Create the OU if it doesn't exist
    if (-not (Get-ADOrganizationalUnit -Filter "Name -eq '$ouName'" -ErrorAction SilentlyContinue)) {
        Write-Log -message "OU '$ouName' does not exist. Creating OU." -source $TaskName -eventID 2200
        New-ADOrganizationalUnit -Name $ouName -Path $((Get-ADDomain).DistinguishedName) -ErrorAction Stop | Out-Null
        Write-Log -message "OU '$ouName' created." -source $TaskName -eventID 2201
    }
    else {
        Write-Log -message "OU $ouName exists, but shouldn't!" -source $TaskName -eventID 2299 -entryType "Warning"
    }

    # Create users in the LabUsers OU using an array and loop
    Write-Log -message "Creating User Accounts." -source $TaskName -eventID 2300
    $users = @(
        @{ Name = "John Smith"; AccountName = "jsmith"; Groups = @() },
        @{ Name = "Jeff Leatherman"; AccountName = "jeffl"; Groups = @() },
        @{ Name = "Ron HelpDesk"; AccountName = "ronhd"; Groups = @("Helpdesk") },
        @{ Name = "John Admin"; AccountName = "johna"; Groups = @("Domain Admins") },
        @{ Name = "Samira Abbasi"; AccountName = "samiraa"; Groups = @("Domain Admins") },
        @{ Name = "Admin Backup"; AccountName = "admin_bak"; Groups = @("Remote IT Admin", "Admin Backup")}
    )

    foreach ($user in $users) {
        try {
            $upn = "$($user.AccountName)@$domainRoot"
            $adUser = Get-GuaranteedUser -Name $user.Name -AccountName $user.AccountName -UPN $upn -UserOuPath $ouPath -AccountPassword $securePassword
            if($null -ne $adUser) {
                foreach ($group in $user.Groups) {
                    if([string]::IsNullOrEmpty($group) -or [string]::IsNullOrWhiteSpace($group)) {
                        Write-Log -message "User $($user.Name) has no groups specified." -source $TaskName -eventID 2301
                    }
                    else 
                    {
                        try {
                            $adGroup = Get-GuaranteedGroup -GroupName $group -GroupOuPath $ouPath
                            if($null -ne $adGroup) {
                                Add-ADGroupMember -Identity $adGroup -Members $adUser -ErrorAction Stop
                                Write-Log -message "User $($user.Name) was added to group $($group) successfully." -source $TaskName -eventID 2302
                            }
                            else {
                                Write-Log -message "Guaranteed AD Group returned is null for group $group" -source $TaskName -eventID 2393 -entryType "Error"
                            }
                        }
                        catch {
                            Write-Log -message "Group Hydration Error $($_.Exception.Message)" -source $TaskName -eventID 2392 -entryType "Error"
                        }
                    }
                }
            }
            else {
                Write-Log -message "Guaranteed User returned is null for user $($user.Name)" -source $TaskName -eventID 2391 -entryType "Error"
            }
        }
        catch {
            Write-Log -message "User Hydration Error: $($_.Exception.Message)" -source $TaskName -eventID 2390 -entryType "Error"
        }
    }
    Write-Log -message "OU, users, groups, and group memberships have been created. DcHyrate Script Completed." -source $TaskName -eventID 2404
}
catch {
    Write-Log -message "ERROR: $($_.Exception.Message)" -source $TaskName -eventID 2099 -entryType "Error"
}
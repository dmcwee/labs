<#
.SYNOPSIS
    Adds a user account to a domain group or removes them during cleanup.

.DESCRIPTION
    This script adds a specified user account to a specified domain group.
    By default, it adds "bad.user" to the "Domain Admins" group.
    Can also perform cleanup operations to remove users from groups and optionally delete the user account.

.PARAMETER UserName
    The username to add to the domain group. Default is "bad.user".

.PARAMETER DomainGroup
    The domain group to add the user to. Default is "Domain Admins".

.PARAMETER CreateUser
    If specified, creates the user account if it doesn't exist.

.PARAMETER Password
    The password for the new user account. Default is "P@ssw0rd123!".

.PARAMETER Cleanup
    If specified, removes the user from the domain group instead of adding them.

.PARAMETER DeleteUser
    If specified with -Cleanup, also deletes the user account after removing from the group.

.EXAMPLE
    .\Invoke-SuspiciousAccountAddition.ps1
    Adds "bad.user" to "Domain Admins" group.

.EXAMPLE
    .\Invoke-SuspiciousAccountAddition.ps1 -UserName "testuser" -DomainGroup "Administrators"
    Adds "testuser" to "Administrators" group.

.EXAMPLE
    .\Invoke-SuspiciousAccountAddition.ps1 -CreateUser
    Creates "bad.user" account and adds it to "Domain Admins" group.

.EXAMPLE
    .\Invoke-SuspiciousAccountAddition.ps1 -Cleanup
    Removes "bad.user" from "Domain Admins" group.

.EXAMPLE
    .\Invoke-SuspiciousAccountAddition.ps1 -Cleanup -DeleteUser
    Removes "bad.user" from "Domain Admins" group and deletes the user account.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$UserName = "bad.user",

    [Parameter(Mandatory = $false)]
    [string]$DomainGroup = "Domain Admins",

    [Parameter(Mandatory = $false)]
    [switch]$CreateUser,

    [Parameter(Mandatory = $false)]
    [string]$Password = "P@ssw0rd123!",

    [Parameter(Mandatory = $false)]
    [switch]$Cleanup,

    [Parameter(Mandatory = $false)]
    [switch]$DeleteUser
)

function New-DomainUser {
    <#
    .SYNOPSIS
        Creates a new user account in Active Directory using PowerShell AD module.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$UserName,

        [Parameter(Mandatory = $true)]
        [string]$Password
    )

    try {
        Write-Host "[*] Creating new user account: $UserName" -ForegroundColor Yellow

        # Convert password to secure string
        $securePassword = ConvertTo-SecureString -String $Password -AsPlainText -Force

        # Create the user account
        $userParams = @{
            Name                 = $UserName
            SamAccountName       = $UserName
            UserPrincipalName    = "$UserName@$($env:USERDNSDOMAIN)"
            DisplayName          = $UserName
            AccountPassword      = $securePassword
            Enabled              = $true
            Path                 = "CN=Users,$((Get-ADDomain).DistinguishedName)"
            ChangePasswordAtLogon = $false
        }
        
        New-ADUser @userParams

        Write-Host "[+] Successfully created user: $UserName" -ForegroundColor Green
        Write-Host "[+] Password: $Password" -ForegroundColor Green
        
        # Return the user object
        return (Get-ADUser -Identity $UserName)
    }
    catch {
        Write-Host "[!] Failed to create user: $_" -ForegroundColor Red
        throw
    }
}

try {
    # Import Active Directory module
    Import-Module ActiveDirectory -ErrorAction Stop

    # Get the domain
    $domain = Get-ADDomain
    Write-Host "[*] Domain: $($domain.DNSRoot)" -ForegroundColor Cyan

    if ($Cleanup) {
        # Cleanup operation - remove user from group and optionally delete user
        Write-Host "[*] Starting cleanup operation..." -ForegroundColor Yellow
        Write-Host "[*] Target User: $UserName" -ForegroundColor Cyan
        Write-Host "[*] Target Group: $DomainGroup" -ForegroundColor Cyan

        # Check if user exists
        try {
            $user = Get-ADUser -Identity $UserName -ErrorAction Stop
            Write-Host "[+] User found: $($user.DistinguishedName)" -ForegroundColor Green
        }
        catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
            Write-Host "[!] User '$UserName' not found in domain." -ForegroundColor Yellow
            Write-Host "[*] Nothing to clean up." -ForegroundColor Yellow
            exit 0
        }

        # Get the group
        try {
            $group = Get-ADGroup -Identity $DomainGroup -ErrorAction Stop
            Write-Host "[+] Group found: $($group.DistinguishedName)" -ForegroundColor Green
        }
        catch {
            Write-Host "[!] Group '$DomainGroup' not found in domain." -ForegroundColor Red
            exit 1
        }

        # Check if user is a member of the group
        $members = Get-ADGroupMember -Identity $DomainGroup -ErrorAction Stop
        if ($members.SamAccountName -contains $UserName) {
            Write-Host "[*] Removing user '$UserName' from group '$DomainGroup'..." -ForegroundColor Yellow
            Remove-ADGroupMember -Identity $DomainGroup -Members $UserName -Confirm:$false
            Write-Host "[+] Successfully removed '$UserName' from '$DomainGroup'!" -ForegroundColor Green
        }
        else {
            Write-Host "[!] User '$UserName' is not a member of '$DomainGroup'." -ForegroundColor Yellow
        }

        # Delete user if requested
        if ($DeleteUser) {
            Write-Host "[*] Deleting user account '$UserName'..." -ForegroundColor Yellow
            Remove-ADUser -Identity $UserName -Confirm:$false
            Write-Host "[+] Successfully deleted user account '$UserName'!" -ForegroundColor Green
        }

        Write-Host "[*] Cleanup completed." -ForegroundColor Green
    }
    else {
        # Normal operation - add user to group
        Write-Host "[*] Starting suspicious account addition simulation..." -ForegroundColor Yellow
        Write-Host "[*] Target User: $UserName" -ForegroundColor Cyan
        Write-Host "[*] Target Group: $DomainGroup" -ForegroundColor Cyan

        # Check if user exists
        try {
            $user = Get-ADUser -Identity $UserName -ErrorAction Stop
            Write-Host "[+] User found: $($user.DistinguishedName)" -ForegroundColor Green
        }
        catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
            if ($CreateUser) {
                Write-Host "[!] User '$UserName' not found. Creating user..." -ForegroundColor Yellow
                $user = New-DomainUser -UserName $UserName -Password $Password
            }
            else {
                Write-Host "[!] User '$UserName' not found in domain." -ForegroundColor Red
                Write-Host "[!] Please create the user first, specify an existing user, or use -CreateUser switch." -ForegroundColor Red
                exit 1
            }
        }

        # Get the group
        try {
            $group = Get-ADGroup -Identity $DomainGroup -ErrorAction Stop
            Write-Host "[+] Group found: $($group.DistinguishedName)" -ForegroundColor Green
        }
        catch {
            Write-Host "[!] Group '$DomainGroup' not found in domain." -ForegroundColor Red
            exit 1
        }

        # Check if user is already a member
        $members = Get-ADGroupMember -Identity $DomainGroup -ErrorAction Stop
        if ($members.SamAccountName -contains $UserName) {
            Write-Host "[!] User '$UserName' is already a member of '$DomainGroup'." -ForegroundColor Yellow
            exit 0
        }

        # Add user to group
        Write-Host "[*] Adding user '$UserName' to group '$DomainGroup'..." -ForegroundColor Yellow
        Add-ADGroupMember -Identity $DomainGroup -Members $UserName

        Write-Host "[+] Successfully added '$UserName' to '$DomainGroup'!" -ForegroundColor Green
        Write-Host "[*] This action may trigger security alerts in Microsoft Defender for Identity." -ForegroundColor Yellow
    }

} catch {
    Write-Host "[!] Error occurred: $_" -ForegroundColor Red
    Write-Host "[!] Exception Type: $($_.Exception.GetType().FullName)" -ForegroundColor Red
    exit 1
}

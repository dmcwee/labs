<#
.SYNOPSIS
    Manages domain account group memberships for privilege escalation testing.

.DESCRIPTION
    This script can create or use an existing domain account and add it to specified privileged groups.
    It also provides cleanup functionality to remove the user from groups or delete the account entirely.
    This is intended for security testing and lab environments only.

.PARAMETER UserName
    The username of the domain account to manage. Required.

.PARAMETER CreateUser
    Switch to create a new domain user account if it doesn't exist.

.PARAMETER Password
    Password for the new user account (required when CreateUser is specified).
    If not provided when creating a user, a random secure password will be generated.

.PARAMETER GroupList
    Array of domain groups to add the user to.
    Default: @("Domain Admins", "Enterprise Admins", "Schema Admins", "Account Operators", "Backup Operators")

.PARAMETER CleanUp
    Switch to remove the user from all specified groups instead of adding.

.PARAMETER DeleteUser
    Switch to delete the user account entirely (can only be used with CleanUp).

.PARAMETER DomainController
    Optional domain controller to target for operations.

.EXAMPLE
    .\Invoke-AccountOverPermissions.ps1 -UserName "testuser" -CreateUser
    Creates a new user "testuser" and adds them to all default privileged groups.

.EXAMPLE
    .\Invoke-AccountOverPermissions.ps1 -UserName "testuser" -GroupList @("Domain Admins", "Backup Operators")
    Adds existing user "testuser" to Domain Admins and Backup Operators groups.

.EXAMPLE
    .\Invoke-AccountOverPermissions.ps1 -UserName "testuser" -CleanUp
    Removes "testuser" from all default privileged groups.

.EXAMPLE
    .\Invoke-AccountOverPermissions.ps1 -UserName "testuser" -CleanUp -DeleteUser
    Removes "testuser" from all groups and deletes the account.

.NOTES
    Requires: Active Directory PowerShell Module
    Requires: Domain Admin or equivalent privileges
    WARNING: This script grants extensive privileges. Use only in controlled lab environments.
#>

[CmdletBinding(DefaultParameterSetName='Add')]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$UserName,

    [Parameter(ParameterSetName='Add')]
    [switch]$CreateUser,

    [Parameter(ParameterSetName='Add')]
    [SecureString]$Password,

    [Parameter()]
    [string[]]$GroupList = @(
        "Domain Admins",
        "Enterprise Admins",
        "Schema Admins",
        "Account Operators",
        "Backup Operators"
    ),

    [Parameter(ParameterSetName='CleanUp')]
    [switch]$CleanUp,

    [Parameter(ParameterSetName='CleanUp')]
    [switch]$DeleteUser,

    [Parameter()]
    [string]$DomainController
)

#Requires -Modules ActiveDirectory

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('Info','Success','Warning','Error')]
        [string]$Level = 'Info'
    )
    
    $colors = @{
        'Info' = 'Cyan'
        'Success' = 'Green'
        'Warning' = 'Yellow'
        'Error' = 'Red'
    }
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $colors[$Level]
}

function New-RandomPassword {
    param(
        [int]$Length = 16
    )
    
    $chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()_+-=[]{}|;:,.<>?"
    $password = -join ((1..$Length) | ForEach-Object { $chars[(Get-Random -Maximum $chars.Length)] })
    return (ConvertTo-SecureString -String $password -AsPlainText -Force)
}

# Build common parameters for AD cmdlets
$adParams = @{}
if ($DomainController) {
    $adParams['Server'] = $DomainController
}

try {
    # Import Active Directory module
    if (-not (Get-Module -Name ActiveDirectory)) {
        Write-Log "Importing Active Directory module..." -Level Info
        Import-Module ActiveDirectory -ErrorAction Stop
    }

    # Get current domain
    $domain = Get-ADDomain @adParams
    Write-Log "Working with domain: $($domain.DNSRoot)" -Level Info

    # CLEANUP MODE
    if ($CleanUp) {
        Write-Log "Starting cleanup operations for user: $UserName" -Level Warning
        
        # Check if user exists
        try {
            $user = Get-ADUser -Identity $UserName @adParams -ErrorAction Stop
            Write-Log "Found user: $($user.DistinguishedName)" -Level Info
        }
        catch {
            Write-Log "User '$UserName' not found. Nothing to clean up." -Level Warning
            return
        }

        # Remove user from specified groups
        Write-Log "Removing user from specified groups..." -Level Info
        $removedCount = 0
        $failedCount = 0

        foreach ($groupName in $GroupList) {
            try {
                $group = Get-ADGroup -Identity $groupName @adParams -ErrorAction Stop
                
                # Check if user is a member
                $isMember = Get-ADGroupMember -Identity $group @adParams -Recursive:$false | 
                            Where-Object { $_.SamAccountName -eq $UserName }
                
                if ($isMember) {
                    Remove-ADGroupMember -Identity $group -Members $user -Confirm:$false @adParams -ErrorAction Stop
                    Write-Log "Removed from group: $groupName" -Level Success
                    $removedCount++
                }
                else {
                    Write-Log "User not a member of: $groupName (skipped)" -Level Info
                }
            }
            catch {
                Write-Log "Failed to remove from group '$groupName': $($_.Exception.Message)" -Level Error
                $failedCount++
            }
        }

        Write-Log "Group removal complete. Removed: $removedCount, Failed: $failedCount" -Level Info

        # Delete user if requested
        if ($DeleteUser) {
            Write-Log "Attempting to delete user account: $UserName" -Level Warning
            try {
                Remove-ADUser -Identity $user -Confirm:$false @adParams -ErrorAction Stop
                Write-Log "User account '$UserName' has been deleted." -Level Success
            }
            catch {
                Write-Log "Failed to delete user: $($_.Exception.Message)" -Level Error
                throw
            }
        }

        Write-Log "Cleanup completed successfully!" -Level Success
        return
    }

    # ADD/CREATE MODE
    Write-Log "Starting privilege escalation operations for user: $UserName" -Level Info

    # Check if user exists
    $userExists = $false
    try {
        $user = Get-ADUser -Identity $UserName @adParams -ErrorAction Stop
        $userExists = $true
        Write-Log "Found existing user: $($user.DistinguishedName)" -Level Info
    }
    catch {
        Write-Log "User '$UserName' not found." -Level Info
    }

    # Create user if needed
    if (-not $userExists) {
        if ($CreateUser) {
            Write-Log "Creating new user account: $UserName" -Level Info
            
            # Generate or use provided password
            if (-not $Password) {
                Write-Log "No password provided. Generating random secure password..." -Level Info
                $Password = New-RandomPassword
                $tempPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
                    [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
                )
                Write-Log "Generated password for user '$UserName': $tempPassword" -Level Warning
                Write-Log "SAVE THIS PASSWORD - it will not be displayed again!" -Level Warning
            }

            try {
                $newUserParams = @{
                    Name = $UserName
                    SamAccountName = $UserName
                    UserPrincipalName = "$UserName@$($domain.DNSRoot)"
                    AccountPassword = $Password
                    Enabled = $true
                    ChangePasswordAtLogon = $false
                    PasswordNeverExpires = $true
                }
                
                $user = New-ADUser @newUserParams @adParams -PassThru -ErrorAction Stop
                Write-Log "User created successfully: $($user.DistinguishedName)" -Level Success
            }
            catch {
                Write-Log "Failed to create user: $($_.Exception.Message)" -Level Error
                throw
            }
        }
        else {
            Write-Log "User does not exist and CreateUser switch not specified." -Level Error
            throw "User '$UserName' not found. Use -CreateUser to create a new account."
        }
    }

    # Add user to groups
    Write-Log "Adding user to privileged groups..." -Level Info
    $addedCount = 0
    $skippedCount = 0
    $failedCount = 0

    foreach ($groupName in $GroupList) {
        try {
            $group = Get-ADGroup -Identity $groupName @adParams -ErrorAction Stop
            
            # Check if user is already a member
            $isMember = Get-ADGroupMember -Identity $group @adParams -Recursive:$false | 
                        Where-Object { $_.SamAccountName -eq $UserName }
            
            if ($isMember) {
                Write-Log "Already a member of: $groupName (skipped)" -Level Info
                $skippedCount++
            }
            else {
                Add-ADGroupMember -Identity $group -Members $user @adParams -ErrorAction Stop
                Write-Log "Added to group: $groupName" -Level Success
                $addedCount++
            }
        }
        catch {
            Write-Log "Failed to add to group '$groupName': $($_.Exception.Message)" -Level Error
            $failedCount++
        }
    }

    Write-Log "Operation complete. Added: $addedCount, Already member: $skippedCount, Failed: $failedCount" -Level Info
    
    if ($addedCount -gt 0) {
        Write-Log "User '$UserName' has been granted extensive privileges!" -Level Success
        Write-Log "WARNING: This account now has elevated permissions. Use responsibly in lab environments only." -Level Warning
    }
}
catch {
    Write-Log "Script execution failed: $($_.Exception.Message)" -Level Error
    Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level Error
    exit 1
}

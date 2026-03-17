param(
    [Parameter()]
    [string]$Username = 'adm_backup',
    
    [Parameter()]
    [string]$Password = 'P@ssw0rd!TestOnly',
    
    [Parameter()]
    [string]$Description = 'Decoy honeytoken - do not use (lab only)',
    
    [Parameter()]
    [string]$OU = 'CN=Users',
    
    [Parameter()]
    [switch]$Cleanup,
    
    [Parameter()]
    [switch]$Force
)

# 2.1 Create a decoy user (enable only for test; don't assign real privileges)
Import-Module ActiveDirectory

# Get the domain DN and UPN suffix from the current domain
$domain = Get-ADDomain
$domainDN = $domain.DistinguishedName
$domainUPN = $domain.Forest

$UPN = "$Username@$domainUPN"

# Construct the full path by combining OU parameter with domain DN
$fullPath = "$OU,$domainDN"

$groupName = 'Remote IT Admin'

# Display runtime banner unless Force is specified
if (-not $Force) {
    Write-Host "`n========================================" -ForegroundColor Cyan
    if ($Cleanup) {
        Write-Host "CLEANUP MODE" -ForegroundColor Yellow
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host "This script will DELETE the following:" -ForegroundColor Yellow
        Write-Host "  - User: $Username"
        Write-Host "  - Group: $groupName"
    } else {
        Write-Host "HONEYTOKEN ACCOUNT CREATION" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host "This script will CREATE the following:" -ForegroundColor Green
        Write-Host "  + User: $Username"
        Write-Host "  + UPN: $UPN"
        Write-Host "  + Path: $fullPath"
        Write-Host "  + Group: $groupName"
        Write-Host "  + Description: $Description"
    }
    Write-Host "========================================`n" -ForegroundColor Cyan
    
    $response = Read-Host "Do you want to continue? (Y/N)"
    if ($response -ne 'Y' -and $response -ne 'y') {
        Write-Host "Operation cancelled by user." -ForegroundColor Yellow
        exit
    }
}

# Cleanup mode: Remove user and group
if ($Cleanup) {
    Write-Host "`nStarting cleanup..." -ForegroundColor Yellow
    
    # Remove user
    if (Get-ADUser -Filter "SamAccountName -eq '$Username'" -ErrorAction SilentlyContinue) {
        Remove-ADUser -Identity $Username -Confirm:$false
        Write-Host "Deleted user: $Username" -ForegroundColor Green
    } else {
        Write-Host "User not found: $Username" -ForegroundColor Yellow
    }
    
    # Remove group
    if (Get-ADGroup -Filter "Name -eq '$groupName'" -ErrorAction SilentlyContinue) {
        Remove-ADGroup -Identity $groupName -Confirm:$false
        Write-Host "Deleted group: $groupName" -ForegroundColor Green
    } else {
        Write-Host "Group not found: $groupName" -ForegroundColor Yellow
    }
    
    Write-Host "`nCleanup completed.`n" -ForegroundColor Green
    exit
}

# Normal mode: Create user and group
$secPwd = ConvertTo-SecureString $Password -AsPlainText -Force
New-ADUser -Name $Username `
  -SamAccountName $Username `
  -UserPrincipalName $UPN `
  -AccountPassword $secPwd `
  -Enabled $true `
  -Path $fullPath `
  -Description $Description

# Create "Remote IT Admin" group if it doesn't exist and add the user to it
if (!(Get-ADGroup -Filter "Name -eq '$groupName'" -ErrorAction SilentlyContinue)) {
    New-ADGroup -Name $groupName `
      -GroupScope Global `
      -GroupCategory Security `
      -Path $fullPath `
      -Description 'Remote IT Administration group'
    Write-Host "Created group: $groupName"
} else {
    Write-Host "Group already exists: $groupName"
}

# Add the user to the group
Add-ADGroupMember -Identity $groupName -Members $Username
Write-Host "Added $Username to $groupName"
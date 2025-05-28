param(
    [securestring]$password
)
# Import Active Directory module
Import-Module ActiveDirectory

# Set OU and domain variables
$ouName = "LabUsers"
$domain = (Get-ADDomain).DistinguishedName
$ouPath = "OU=$ouName,$domain"

# Create the OU if it doesn't exist
if (-not (Get-ADOrganizationalUnit -Filter "Name -eq '$ouName'" -ErrorAction SilentlyContinue)) {
    New-ADOrganizationalUnit -Name $ouName -Path $domain
}

# Create users in the LabUsers OU
New-ADUser -Name "John Smith" -SamAccountName "jsmith" -AccountPassword $password -Enabled $true -Path $ouPath
New-ADUser -Name "Ron HelpDesk" -SamAccountName "ronhd" -AccountPassword $password -Enabled $true -Path $ouPath
New-ADUser -Name "John Admin" -SamAccountName "johna" -AccountPassword $password -Enabled $true -Path $ouPath

# Create helpdesk group in the LabUsers OU
New-ADGroup -Name "helpdesk" -GroupScope Global -Path $ouPath

# Add John Admin to Domain Admins group
Add-ADGroupMember -Identity "Domain Admins" -Members "johna"

Write-Host "OU, users, group, and group membership have been created."
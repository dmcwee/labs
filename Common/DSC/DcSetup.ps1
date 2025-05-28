param(
	[string]$DomainName,
	[string]$NetBiosName,
	[string]$Password
)

# Install AD DS and RSAT tools
Install-WindowsFeature -Name AD-Domain-Services, RSAT-AD-Tools -IncludeManagementTools

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

Write-Host "Active Directory Domain Services and new domain '$DomainName' have been installed."
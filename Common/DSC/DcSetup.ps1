param(
	[string]$DomainName,
	[string]$NetBiosName,
	[securestring]$Password
)

# Install AD DS and RSAT tools
Install-WindowsFeature -Name AD-Domain-Services, RSAT-AD-Tools -IncludeManagementTools

# Import ADDSDeployment module
Import-Module ADDSDeployment

# Install new forest and domain controller
Install-ADDSForest `
    -DomainName $DomainName `
	-DomainNetbiosName $NetBiosName `
    -SafeModeAdministratorPassword $Password `
    -InstallDNS `
    -Force

Write-Host "Active Directory Domain Services and new domain '$DomainName' have been installed."
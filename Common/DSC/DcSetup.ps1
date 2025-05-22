params(
	[string]$DomainName,
	[string]$NetBiosName,
	[string]$PlainTextPassword
)
# Install AD DS and RSAT tools
Install-WindowsFeature -Name AD-Domain-Services, RSAT-AD-Tools -IncludeManagementTools

# Import ADDSDeployment module
Import-Module ADDSDeployment

# Set domain variables
$SafeModePassword = (ConvertTo-SecureString $PlainTextPassword -AsPlainText -Force)

# Install new forest and domain controller
Install-ADDSForest `
    -DomainName $DomainName `
	-DomainNetbiosName $NetBiosName `
    -SafeModeAdministratorPassword $SafeModePassword `
    -InstallDNS `
    -Force

Write-Host "Active Directory Domain Services and new domain '$DomainName' have been installed."
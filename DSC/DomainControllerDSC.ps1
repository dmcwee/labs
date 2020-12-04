Configuration Main
{

	Param ( 
		[PSCredential] $adminAccount,
		[String]$domainName
	)

	Import-DscResource -ModuleName PSDesiredStateConfiguration
	Import-DscResource -ModuleName xActiveDirectory

	[PSCredential]$Creds = New-Object -TypeName PSCredential ($adminAccount.UserName, $adminAccount.Password)
	$OUPath = ($domainName.split('.') | ForEach-Object { "DC=$_" }) -join ','
	$UserPath = "OU=LabUsers," + $OUPath
	
	Node localhost
	{
		Log WriteOU {
			Message = "The OUPath is " + $OUPath
		}

		Log WriteUserPath {
			Message = "The Userath is " + $UserPath
		}

		WindowsFeature ADDomainServices {
			Name="AD-Domain-Services"
			Ensure="Present"
	 	}

		WindowsFeature DNS {
			Name="DNS"
			Ensure="Present"
			IncludeAllSubFeature = $true
		}

		WindowsFeature ADTools {
			Name="RSAT-AD-Tools"
			Ensure = "Present"
			IncludeAllSubFeature = $true
		}

		<#
		WindowsFeature DNSTools {
			Name="RSAT-DNS-Server"
			Ensure = "Present"
			IncludeAllSubFeature = $true
		}
		#>

		xADDomain CreateDomain {
			DomainName = $domainName
            DomainAdministratorCredential = $Creds
			SafemodeAdministratorPassword = $Creds
            DependsOn = "[WindowsFeature]ADDomainServices"
		}

		<#
		File AADConnect {
			SourcePath = "https://download.microsoft.com/download/B/0/0/B00291D0-5A83-4DE7-86F5-980BC00DE05A/AzureADConnect.msi"
			DestinationPath = "C:\Users\Public\Download"
		}
		#> 
		
		xWaitForADDomain CreatedDomain {
			DomainName = $domainName
			RebootRetryCount = 2
			RetryIntervalSec = 600
			DependsOn = "[xADDomain]CreateDomain"
		}
		
		xADOrganizationalUnit LabUsers {
			Name = 'LabUsers'
			Path = $OUPath
			ProtectedFromAccidentalDeletion = $true
			Ensure = 'Present'
			DependsOn = "[xWaitForADDomain]CreatedDomain"
		}

		xADUser JeffL {
			Ensure = 'Present'
			UserName = 'JeffL'
			Password = $Creds
			DisplayName = "Jeff Leatherman"
			PasswordNeverResets = $true
			DomainName = $domainName
			Path = $UserPath
			DependsOn = "[xADOrganizationalUnit]LabUsers"
		}

		xADUser RonHD {
			Ensure = 'Present'
			UserName = 'RonHD'
			Password = $Creds
			DisplayName = "Ron Helpdesk"
			PasswordNeverExpires = $true
			DomainName = $domainName
			Path = $UserPath
			DependsOn = "[xADOrganizationalUnit]LabUsers"
		}

		xADUser SamiraA {
			Ensure = 'Present'
			UserName = 'SamiraA'
			Password = $Creds
			DisplayName = "Samira Abbasi"
			PasswordNeverExpires = $true
			DomainName = $domainName
			Path = $UserPath
			DependsOn = "[xADOrganizationalUnit]LabUsers"
		}

		xADUser AATPService {
			Ensure = 'Present'
			UserName = 'AATPService'
			Password = $Creds
			DisplayName = "Azure ATP Service"
			PasswordNeverExpires = $true
			DomainName = $domainName
			Path = $UserPath
			DependsOn = "[xADOrganizationalUnit]LabUsers"
		}

		xADGroup HelpDesk {
			GroupName = 'HelpDesk'
			GroupScope = 'Global'
			Category = 'Security'
			Description = 'HelpDesk Security Group'
			Members = 'RonHD'
			Ensure = 'Present'
			DependsOn = "[xADUser]RonHD"
		}
 	}
}
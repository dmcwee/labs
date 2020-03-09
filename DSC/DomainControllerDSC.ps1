Configuration Main
{

	Param ( 
		[String]$nodeName, 
		[String]$driveLetter = "L", 
		[PSCredential] $adminAccount,
		[String]$domainName,
		[int] $retryAttempts = "60",
		[int] $waitTime = "60"
	)

	Import-DscResource -ModuleName PSDesiredStateConfiguration, StorageDsc, ActiveDirectoryDsc
	[PSCredential ]$Creds = New-Object -TypeName PSCredential ($adminAccount.UserName, $adminAccount.Password)
	$OUPath = ($domainName.split('.') | foreach { "DC=$_" }) -join ','
	
	Node localhost
	{
		WindowsFeature ADDomainServices {
			Name="AD-Domain-Services"
			Ensure="Present"
	 	}

		WindowsFeature DNS {
			Name="DNS"
			Ensure="Present"
		}

		WindowsFeature ADTools {
			Name="RSAT-AD-Tools"
			Ensure = "Present"
			IncludeAllSubFeature = $true
		}

		<#
		WaitForDisk Disk2 {
			DiskId = 2
			RetryIntervalSec = $waitTime
			RetryCount = $retryAttempts
		}

		Disk ADDisk {
			DiskId = 2
			DriveLetter = $driveLetter
			FSLabel = "ADData"
			DependsOn = "[WaitForDisk]Disk2"
		}
		#>

		ADDomain CreateDomain {
			DomainName = $domainName
            Credential = $Creds
			SafemodeAdministratorPassword = $Creds
            DependsOn = "[WindowsFeature]ADDomainServices"
		}

		
		File AADConnect {
			SourcePath = "https://download.microsoft.com/download/B/0/0/B00291D0-5A83-4DE7-86F5-980BC00DE05A/AzureADConnect.msi"
			DestinationPath = "C:\Users\Public\Download"
		}
		
		ADOrganizationalUnit LabUsers {
			Name = 'LabUsers'
			Path = $OUPath
			ProtectedFromAccidentalDeletion = $true
			Ensure = 'Present'
			DependsOn = "[ADDomain]CreateDomain"
		}

		ADUser JeffL {
			Ensure = 'Present'
			UserName = 'JeffL'
			Password = $Creds
			DisplayName = "Jeff Leatherman"
			PasswordNeverResets = $true
			DomainName = $domainName
			Path = 'CN=LabUsers,' + $OUPath
			DependsOn = "[ADOrganizationalUnit]LabUsers"
		}

		ADUser RonHD {
			Ensure = 'Present'
			UserName = 'RonHD'
			Password = $Creds
			DisplayName = "Ron Helpdesk"
			PasswordNeverExpires = $true
			DomainName = $domainName
			Path = 'CN=LabUsers,' + $OUPath
			DependsOn = "[ADOrganizationalUnit]LabUsers"
		}

		ADUser SamiraA {
			Ensure = 'Present'
			UserName = 'SamiraA'
			Password = $Creds
			DisplayName = "Samira Abbasi"
			PasswordNeverExpires = $true
			DomainName = $domainName
			Path = 'CN=LabUsers,' + $OUPath
			DependsOn = "[ADOrganizationalUnit]LabUsers"
		}

		ADUser AATPService {
			Ensure = 'Present'
			UserName = 'AATPService'
			Password = $Creds
			DisplayName = "Azure ATP Service"
			PasswordNeverExpires = $true
			DomainName = $domainName
			Path = 'CN=LabUsers,' + $OUPath
			DependsOn = "[ADOrganizationalUnit]LabUsers"
		}

		ADGroup HelpDesk {
			GroupName = 'HelpDesk'
			GroupScope = 'Global'
			Category = 'Security'
			Description = 'HelpDesk Security Group'
			Members = 'RonHD'
			Ensure = 'Present'
			DependsOn = "[ADUser]RonHD"
		}
 	}
}
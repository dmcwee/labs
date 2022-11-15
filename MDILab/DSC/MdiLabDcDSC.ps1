Configuration Main
{

	Param ( 
		[PSCredential] $adminAccount,
		[String]$domainName
	)

	Import-DscResource -ModuleName 'PSDesiredStateConfiguration'
	Import-DScResource -ModuleName 'ComputerManagementDsc'
	Import-DscResource -ModuleName 'ActiveDirectoryDsc'

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

		IEEnhancedSecurityConfiguration DisableForAdmin {
			Role = 'Administrators'
			Enabled = $false
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

		ADDomain CreateDomain {
			DomainName = $domainName
            Credential = $Creds
			SafemodeAdministratorPassword = $Creds
            DependsOn = "[WindowsFeature]ADDomainServices"
		}
		
		WaitForADDomain CreatedDomain {
			DomainName = $domainName
			RestartCount = 2
			WaitTimeout = 600
			DependsOn = "[ADDomain]CreateDomain"
		}
		
		ADOrganizationalUnit LabUsers {
			Name = 'LabUsers'
			Path = $OUPath
			ProtectedFromAccidentalDeletion = $true
			Ensure = 'Present'
			DependsOn = "[WaitForADDomain]CreatedDomain"
		}

		ADUser JeffL {
			Ensure = 'Present'
			UserName = 'JeffL'
			Password = $Creds
			DisplayName = "Jeff Leatherman"
			PasswordNeverResets = $true
			DomainName = $domainName
			Path = $UserPath
			DependsOn = "[ADOrganizationalUnit]LabUsers"
		}

		ADUser RonHD {
			Ensure = 'Present'
			UserName = 'RonHD'
			Password = $Creds
			DisplayName = "Ron Helpdesk"
			PasswordNeverExpires = $true
			DomainName = $domainName
			Path = $UserPath
			DependsOn = "[ADOrganizationalUnit]LabUsers"
		}

		ADUser SamiraA {
			Ensure = 'Present'
			UserName = 'SamiraA'
			Password = $Creds
			DisplayName = "Samira Abbasi"
			PasswordNeverExpires = $true
			DomainName = $domainName
			Path = $UserPath
			DependsOn = "[ADOrganizationalUnit]LabUsers"
		}

		ADUser AATPService {
			Ensure = 'Present'
			UserName = 'AATPService'
			Password = $Creds
			DisplayName = "Azure ATP Service"
			PasswordNeverExpires = $true
			DomainName = $domainName
			Path = $UserPath
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

		ADGroup DomainAdmins {
			GroupName = "Domain Admins"
			MembersToInclude = "SamiraA"
			DependsOn = "[ADUser]SamiraA"
		}
 	}
}
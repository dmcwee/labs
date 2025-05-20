Configuration Prerequisites {
	
	Import-DscResource -ModuleName 'PSDesiredStateConfiguration'
    Import-DScResource -ModuleName 'ComputerManagementDsc'

    Node localhost {
        WindowsFeature ADDomainServices {
			Name="AD-Domain-Services"
			Ensure="Present"
	 	}

		WindowsFeature DNS {
			Name="DNS"
			Ensure="Present"
			IncludeAllSubFeature = $true
		}

		WindowsFeature DNSTools {
			Name="RSAT-DNS-Server"
			Ensure="Present"
			IncludeAllSubFeature = $true
		}

		WindowsFeature ADTools {
			Name="RSAT-AD-Tools"
			Ensure = "Present"
			IncludeAllSubFeature = $true
		}

        Script ActiveDirectoryDscResource {
            GetScript = {
				$module = Import-Module -Name ActiveDirectoryDsc
                return $module
            }
            SetScript = {
                # Install-Module -Name ActiveDirectoryDsc -AllowClobber -Force -SkipPublisherCheck
				Install-Module -Name ActiveDirectoryDsc -Repository PSGallery -Force
            }
            TestScript = {
				$import = Import-Module -Name ActiveDirectoryDsc
				return $null -ne $import
            }
        }

    }
}

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
			Message = "The UserPath is " + $UserPath
		}

		ADDomain CreateDomain {
			DomainName = $domainName
            Credential = $Creds
			SafemodeAdministratorPassword = $Creds
		}

		WaitForADDomain CreatedDomain {
			DomainName = $domainName
			RestartCount = 2
			WaitTimeout = 600
			DependsOn = "[ADDomain]CreateDomain"
		}

        PendingReboot AfterAdSetup {
			Name = "After A Setup"
			DependsOn = "[WaitForADDomain]CreatedDomain"
		}

        ADOrganizationalUnit LabUsers {
            Name = 'LabUsers'
            Path = $UserPath
            ProtectedFromAccidentalDeletion = $true
            Ensure = 'Present'
            DependsOn = "[PendingReboot]AfterAdSetup"
        }

        ADUser JamesA {
			Ensure = 'Present'
			UserName = 'JamesA'
			Password = $Creds
			DisplayName = "James Admin"
			PasswordNeverResets = $true
			DomainName = $domainName
			Path = $UserPath
			DependsOn = "[ADOrganizationalUnit]LabUsers"
		}

        ADUser JohnHD {
			Ensure = 'Present'
			UserName = 'JohnHD'
			Password = $Creds
			DisplayName = "John Helpdesk"
			PasswordNeverResets = $true
			DomainName = $domainName
			Path = $UserPath
			DependsOn = "[ADUser]JamesA"
		}

        ADGroup HelpDesk {
			GroupName = 'HelpDesk'
			GroupScope = 'Global'
			Category = 'Security'
			Description = 'HelpDesk Security Group'
			Members = 'JohnHD','JamesA'
			Ensure = 'Present'
			DependsOn = "[ADUser]JohnHD"
		}

		ADGroup DomainAdmins {
			GroupName = "Domain Admins"
			MembersToInclude = "JamesA"
			DependsOn = "[ADUser]JamesA"
		}
	}
}
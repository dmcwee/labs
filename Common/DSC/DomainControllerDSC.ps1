Configuration Main
{
	Param ( 
		[PSCredential] $adminAccount,
		[String]$domainName
	)

	Import-DscResource -ModuleName 'PSDesiredStateConfiguration'
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
	}
}
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

	Import-DscResource -ModuleName PSDesiredStateConfiguration, StorageDsc, xActiveDirectory
	[PSCredential ]$Creds = New-Object -TypeName PSCredential ($adminAccount.UserName, $adminAccount.Password)

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
		
		xADDomain CreateDomain {
			DomainName = $domainName
            DomainAdministratorCredential = $Creds
            SafemodeAdministratorPassword = $Creds
            DnsDelegationCredential = $DNSDelegationCred
            DependsOn = "[WindowsFeature]ADDomainServices", "[Disk]ADDisk"
		}
 	}
}
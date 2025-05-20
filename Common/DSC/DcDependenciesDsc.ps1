Configuration Main {
	
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
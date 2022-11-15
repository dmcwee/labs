Configuration Main
{

Param ()

Import-DscResource -ModuleName PSDesiredStateConfiguration

Node localhost
  {
	  WindowsFeature ADFS {
		  Name="ADFS-Federation"
		  Ensure = "Present"
		}
		
		WindowsFeature ADPowerShell {
			Name="RSAT-AD-PowerShell"
			Ensure = "Present"
		}

		#Add AD Tools to help with Hybrid Deployment & Device Registration Steps
		WindowsFeature ADTools {
			Name="RSAT-AD-Tools"
			Ensure = "Present"
			IncludeAllSubFeature = $true
		}
  }
}
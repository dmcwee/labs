Configuration Main
{

Param ()

Import-DscResource -ModuleName PSDesiredStateConfiguration

Node localhost
  {
	  WindowsFeature WAP {
		  Name = "Web-Application-Proxy"
		  Ensure = "Present"
		}
		
		WindowsFeature WAP-Mgmt {
			Name = "RSAT-RemoteAccess"
			Ensure = "Present"
			IncludeAllSubFeature = $true
		}
  }
}
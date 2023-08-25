Configuration Main
{

	Param ( 
		[PSCredential] $adminAccount,
		[String]$domainName
	)

    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'
	Import-DScResource -ModuleName 'ComputerManagementDsc'

    Node localhost
	{
        WindowsCapability RSAT-GPO
        {
            Name = "Rsat.GroupPolicy.Management.Tools~~~~0.0.1.0"
            Ensure = "Present"
        }

        File VictimPcScript {
            Ensure = "Present"
            Type = "File"
            Recurse = $true
            DestinationPath = "C:\lab\Invoke-VictimPcConfig.ps1"
            SourcePath = "https://raw.githubusercontent.com/dmcwee/labs/dev/MDILab/scripts/Invoke-VictimPcConfig.ps1"
        }

        File AdminPcScript {
            Ensure = "Present"
            Type = "File"
            Recurse = $true
            DestinationPath = "C:\lab\Invoke-AdminPcConfig.ps1"
            SourcePath = "https://raw.githubusercontent.com/dmcwee/labs/dev/MDILab/scripts/Invoke-AdminPcConfig.ps1"
        }
    }
}
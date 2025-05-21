# Configuration Prerequisites {
	
# 	Import-DscResource -ModuleName 'PSDesiredStateConfiguration'

#     Node localhost {
#         WindowsFeature ADDomainServices {
# 			Name="AD-Domain-Services"
# 			Ensure="Present"
# 	 	}

# 		WindowsFeature DNS {
# 			Name="DNS"
# 			Ensure="Present"
# 			IncludeAllSubFeature = $true
# 		}

# 		WindowsFeature DNSTools {
# 			Name="RSAT-DNS-Server"
# 			Ensure="Present"
# 			IncludeAllSubFeature = $true
# 		}

# 		WindowsFeature ADTools {
# 			Name="RSAT-AD-Tools"
# 			Ensure = "Present"
# 			IncludeAllSubFeature = $true
# 		}

#         Script ActiveDirectoryDscResource {
#             GetScript = {
# 				$module = Import-Module -Name ActiveDirectoryDsc -ErrorAction SilentlyContinue
#                 return $module
#             }
#             SetScript = {
#                 # Install-Module -Name ActiveDirectoryDsc -AllowClobber -Force -SkipPublisherCheck
# 				Install-Module -Name ActiveDirectoryDsc -Repository PSGallery -Force
#             }
#             TestScript = {
# 				$import = Import-Module -Name ActiveDirectoryDsc -ErrorAction SilentlyContinue
# 				return $null -ne $import
#             }
#         }

# 		Script ComputerManagementDsc {
#             GetScript = {
# 				$module = Import-Module -Name ComputerManagementDsc -ErrorAction SilentlyContinue
#                 return $module
#             }
#             SetScript = {
#                 # Install-Module -Name ComputerManagementDsc -AllowClobber -Force -SkipPublisherCheck
# 				Install-Module -Name ComputerManagementDsc -Repository PSGallery -Force
#             }
#             TestScript = {
# 				$import = Import-Module -Name ComputerManagementDsc -ErrorAction SilentlyContinue
# 				return $null -ne $import
#             }
#         }
#     }
# }

$modules = @("ComputerManagementDsc", "ActiveDirectoryDsc")
$modules | ForEach-Object {
	Install-Module -Name $_ -Repository PSGallery -Force
}

$features = @("AD-Domain-Services", "DNS", "RSAT-DNS-Server", "RSAT-AD-Tools")
$features | ForEach-Object {
	Install-WindowsFeature -Name $_ -IncludeManagementTools -IncludeAllSubFeature
}
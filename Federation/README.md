# Federation

**Note**
It has been a while since this lab was created and used last.  Consider using the official AD FS deployment from Microsoft for a more robust solution.  [Microsoft AD FS Template Documentation](https://docs.microsoft.com/en-us/windows-server/identity/ad-fs/deployment/how-to-connect-fed-azure-adfs#template-for-deploying-ad-fs-in-azure)

## Defaults
### VMs Created (Updated 12/4/2020)
1. One Active Directory Server
1. One Active Directory Federation Server (Will not be deployed if using the AzATP parameter file)
1. One Web Application Proxy Server (Will not be deployed if using the AzATP parameter file)
1. One Client VM (2 VMs will be deployed when using the AzATP parameter file)

### VM Size
VMs are created using the *Basic_A2* size

### VM Schedule
Currently all VMs will shutdown daily at 1900 (7PM) EST

### Admin Account
The default name for the admin account is `labadmin`.

### DSC Configuration
#### Active Directory
Actions performed by the Domain Controller DSC:
1. The Active Directory DSC installs the AD, AD Tools, and DNS Features.  
1. The DSC then configures AD with the provided Domain Name and Administrator credentials.
1. Download Azure Active Directory to the Public Downloads folder
1. Create the OU 'LabUsers'
1. Create 3 Users JeffL, RonHD, and SamiraA in the 'LabUsers' OU
1. Create User AATPService for use with Azure ATP service
1. Create Group HelpDesk and add user RonHD as a member
The user accounts JeffL, RonHD, SamiraA, and AATPService are created with the same password as the Lab's default password.  These accounts are created to support the Azure ATP Security Lab found [here](https://docs.microsoft.com/en-us/azure-advanced-threat-protection/atp-playbook-lab-overview)

#### Active Directory Federation Service
Actions performed by the ADFS DSC:
1. The ADFS DSC installs the ADFS, AD Powershell, and AD Tools Features

#### Web Application Proxy
Actions performed by the Web Application Proxy DSC:
1. The WAP DSC installs the WAP and WAP Management Features

## How To deploy this template
### Assumptions
* You have the necessary Azure Powershell Module installed on your machines
* You have an Azure Subscription and the permissions necessary to provision VMs there
* You have the necessary permissions on your local machine to create certificates

### Steps (Updated 12/14/2020)
1. Cloning the repository <del>or downloading [azuredeploy.json](https://raw.githubusercontent.com/dmcwee/idamlab/master/azuredeploy.json)</del> to your local machine
1. Run the Powershell script ```deploy-lab.ps1 -ResourceGroupName [your RG name here] -ResourceGroupLocation [your RG location here]``` 
<del>
1. Use the following Powershell command to create an Azure Resource Group 
>New-AzureRmResourceGroup -Name [resource group name] -Location [desired azure region]
1. Use the following Powershell command to start the Deployment to your recently
>New-AzureRmResourceGroupDeployment -Name [a deployment job name] -ResourceGroupName [resource group name used in the above command] -TemplateFile [relative path to the azuredeploy.json file]
</del>

### Post Deployment Steps (Updated 12/4/2020)
1. I recommend rebooting all machines after performing the deployment.  This seems to resolve a lot of the RDP issues you might experience.
<del>
1. Complete configuration of the VNet Gateway to provide Point-to-Site VPN capabilities to the lab.
   1. In Azure Portal Open the Resource Group and click on the *{resourcegroupname}-GW*
   1. On the Gateway Blade under *Settings* click on *Point-to-Site Configuration*
   1. Follow steps [starting here](https://docs.microsoft.com/en-us/azure/vpn-gateway/vpn-gateway-howto-point-to-site-resource-manager-portal#generatecert) to configure the Point-to-Site settings.
   *You can use the New-P2SCertificate.ps1 powershell script to generate self signed Point-to-Site Authentication certificates*
</del>

1. In the Azure Portal go to the VNet Gateway and download and install the Point-to-Site Client.
1. Verify that the AD Domain has been installed and configured
1. Verify the ADFS Server has the ADFS feature and tools installed and join it to the domain
1. Verify the WAP Server has the Web Application Proxy feature and tools installed.  Depending on your deployment plan you may or may not join this to your domain
1. Perform the ADFS installation and set up process
1. Register your WAP with your Public (GoDaddy, Dyn, etc.) DNS provider
1. Join the Windows 10 computer(s) to the domain.

## Customize this deployment (Updated 12/4/2020)
The following parameters can be overloaded using a deployment parameter file.  

Parameter | Default Value | Allowed Values
--------- | ------------- | --------------
StorageType | Standard_LRS | Standard_LRS, Standard_ZRS, Standard_GRS, Standard_RAGRS, Premium_LRS
ServerOsVersion | 2016-Datacenter | 2008-R2-SP1, 2012-Datacenter, 2012-R2-Datacenter, 2016-Datacenter, 2019-Datacenter
ClientOsVersion | Windows-10-N-x64 | Win7-SP1-ENT-N-x64, Win81-ENT-N-x64, Windows-10-N-x64
VmSize | Basic_A2 | Basic_A1, Basic_A2, Basic_A3, Basic_A4, Standard_A1, Standard_A2, Standard_A3, Standard_A4
AdminUserName | labadmin | *string*
AdServerName | Demo-AD | *string*
IncludeADFS | true | *bool*
ADFSServerName | Demo-ADFS | *string*
IncludeWAP | true | *bool*
WAPServerName | Demo-WAP | *string*
ClientComputerNames | Demo-Client | *array*
gatewayType | Vpn | Vpn, ExpressRoute
vpnGatewayGeneration | Generation1 | *string*
vpnType | RouteBased | RouteBased, PolicyBased
sku | VpnGW1 | *string*
gatewayRootCert | | *string*
gatewayRootCertName | gatewayrootcert | *string*
DSCLocation | | **Warning:** Modifying this value could cause this template to fail deployment.
AdDscFile | DomainControllerDSC.ps1 | *string*
AdfsDscFile | ADFSDSC.ps1 | *string*
WapDscFile | WAPDSC.ps1 | *string*

### How to change a default parameter's value
The following is an example of a parameters JSON file which changes the value of the *VmSize* parameter.

```
{
  "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
      "VmSize": {
          "value": "Basic_A1"
      }
  }
}
```


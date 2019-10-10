# Lab for IDAM

**Warning: This is in development and should NOT be used yet.  Instructions are still very INCOMPLETE**

## Defaults
#### TODO in this section
- [X] List the VMs created by this template
- [X] List the default size of VMs created
- [X] List the daily shutdown schedule of the VMs
- [X] List the default admin username for this template
- [ ] Detail the DSC settings?

### VMs Created
1. One Active Directory Server
1. One Active Directory Federation Server
1. One Web Application Proxy Server
1. One Client VM

### VM Size
VMs are created using the *Basic_A2* size

### VM Schedule
Currently all VMs will shutdown daily at 1900 (7PM)

### Admin Account
The default name for the admin account is `labadmin`.

## How To deploy this template
#### TODO in this section
- [X] Document Assumptions
- [X] Document the steps to deploy this into a user's Azure Environment
- [ ] What are next steps after deployment

### Assumptions
* You have the necessary Azure Powershell Module installed on your machines
* You have an Azure Subscription and the permissions necessary to provision VMs there

### Steps
1. Cloning the repository or downloading [azuredeploy.json](https://raw.githubusercontent.com/dmcwee/idamlab/master/azuredeploy.json) to your local machine
1. Use the following Powershell command to create an Azure Resource Group 
>New-AzureRmResourceGroup -Name [resource group name] -Location [desired azure region]
3. Use the following Powershell command to start the Deployment to your recently
>New-AzureRmResourceGroupDeployment -Name [a deployment job name] -ResourceGroupName [resource group name used in the above command] -TemplateFile [relative path to the azuredeploy.json file]

### Post Deployment Steps
1. I recommend rebooting all machines after performing the deployment.  This seems to resolve any lot of the RDP issues you might experience
1. Verify that the AD Domain has been installed and configured
1. Verify the ADFS Server has the ADFS feature and tools installed and join it to the domain
1. Verify the WAP Server has the Web Application Proxy feature and tools installed.  Depending on your deployment plan you may or may not join this to your domain
1. Perform the ADFS installation and set up process
1. Register your WAP with your Public (GoDaddy, Dyn, etc.) DNS provider

## Customize this deployment
The following parameters can be overloaded using a deployment parameter file.  

Parameter | Default Value | Allowed Values
--------- | ------------- | --------------
StorageType | Standard_LRS | Standard_LRS, Standard_ZRS, Standard_GRS, Standard_RAGRS, Premium_LRS
ServerOsVersion | 2016-Datacenter | 2008-R2-SP1, 2012-Datacenter, 2012-R2-Datacenter, 2016-Datacenter, 2019-Datacenter
ClientOsVersion | Windows-10-N-x64 | Win7-SP1-ENT-N-x64, Win81-ENT-N-x64, Windows-10-N-x64
VmSize | Basic_A2 | Basic_A1, Basic_A2, Basic_A3, Basic_A4, Standard_A1, Standard_A2, Standard_A3, Standard_A4
AdminUserName | labadmin | *string*
AdServerName | Demo-AD | *string*
ADFSServerName | Demo-ADFS | *string*
WAPServerName | Demo-WAP | *string*
ClientComputerName | Demo-Client | *string*
DSCLocation | | **Warning:** Modifying this value could cause this template to fail deployment.

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

## Project TODOs
- [ ] Add a Gateway so only the WAP has a Publicly accessible IP and all VMs can be directly RDP'ed to
- [ ] Include automatic download of the AAD Connect application to the AD server
- [ ] Fix the AD server DSC so AD folder and files will be located on non-cached disk
- [ ] Update Active Directory DSC to use the latest version
# idamlab
Lab for IDAM

# Defaults
All machines will be created using the Basic_A2 size
One AD, One ADFS, and One WAP will be automatically provisioned
One Client VM (Windows 10) will be created to support internal vs. external testing of ADFS behavior
The default admin username is *labadmin*

# Deploy this template
From powershell run the following command
New-AzureRmResourceGroup -Name [the desired name of the resource group] -Location [a location of your choosing]

New-AzureRmResourceGroupDeployment -Name [a deployment name, this can be the same as the resource group or any other text value] -ResourceGroupName [resource group name used in the above command] -TemplateFile [relative path to the azuredeploy.json file]
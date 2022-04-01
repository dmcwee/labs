# Defender for Endpoint Scurity Lab
This is a lab environment for testing of MDE scenarios including onboarding, offboarding, device configuration, and monitoring.

## Deployment Instructions
1. Generate a root and child certificate for the Gateway VPN using [these instructions](../VPN-Setup.md)
1. Open the Azure Portal in a seperate tab in your browser
1. Use the Deploy to Azure button below to deploy the lab to your Azure Environment
    1. **Required:** Specify a Resource Group where the lab will be deployed
    1. **Required:** Provide an Admin Password
    1. *Recommended:* Select the region where the lab should be deployed if using a new resource group
    1. *Recommended:* Update the Admin User Name to your desired name
    1. *Recommended:* Specify a Gateway Cert Name
    1. *Recommended:* Specify the Gateway Cert Data 

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fdmcwee%2Flabs%2Fdev%2FMDELab%2Fazuredeploy.json)

## Post Deployment
While the Active Directory server will be created none of the machines will be AD Joined.  If you would like to perform onboarding with GPO then you need to manually domain join the deisred machines.

If you did not provide the Gateway Certificate during provisioning you will need to provide those configurations in the Azure Portal.
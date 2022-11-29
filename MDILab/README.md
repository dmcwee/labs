# Defender for Identity Security Alert Lab
This is a simplified deployment for the Defender for Identity [Security Alert Lab](https://docs.microsoft.com/en-us/defender-for-identity/playbook-lab-overview)

## MDI Event 1644 DSC
29 Nov 2022 - Added the [Registry settings recommended by MDI](https://learn.microsoft.com/en-us/defender-for-identity/configure-windows-event-collection#event-id-1644) to the AD Desired State Configuration. The specific settings are also available in a [standalone DSC file](./DSC/MDIEventDsc.ps1) which can be deployed to other environments.

## Deployment Instructions
1. Open the Azure Portal in a seperate tab in your browser
1. Use the Deploy to Azure button below to deploy the lab to your Azure Environment
    1. **Required:** Specify a Resource Group where the lab will be deployed
    1. **Required:** Provide an Admin Password
    1. *Recommended:* Select the region where the lab should be deployed if using a new resource group
    1. *Recommended:* Update the Admin User Name to your desired name

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fdmcwee%2Flabs%2Fmaster%2FMDILab%2Fazuredeploy.json)

**Notes:** 
1. **DO NOT** change the Server OS Version, this will impact how the lab runs
1. **DO NOT** change the DSC Location or AD DSC File parameters
1. The VPN Root Cert and Root Cert Name are not required during deployment.

## Post Deployment Setup
1. Use the New-P2SCertificate.ps1 script, found [here](../Common/New-P2SCertificate.ps1) to create a new Root & Child certificate pair for use with the Point-to-Site Gateway
    1. Copy the text from the rootcert.txt file that the script generates in the folder where it is run or from the console's on-screen output
1. In the Azure Portal go to the Resource Group where the lab was created and find the Virtual Network Gateway Resource that was created and click on it
    1. Go to the Point-to-Site Configuration
    1. Provide a name for the Root Certificate
    1. Paste the output from the above step into the Public certificate data field
    1. Save the changes
    1. After the changes have been saved click the Download VPN client button
1. Install the appropriate VPN client for your OS
1. Connect the to the Point-to-Site VPN
1. RDP to Victim-PC 
    1. Set the VM's DNS to point to the ContosoDC1 IP address as the primary DNS. *When the DNS is reset the RDP session will likely be disconnected and RDP to the VM won't work until rebooted.*
    1. Reboot Victim-PC from the Azure Portal
    1. Reconnect to Victim-PC and domain join it to the contoso.com domain
1. RDP to Admin-PC
    1. Set the VM's DNS to point to the ContosoDC1 IP address as the Primary DNS.*When the DNS is reset the RDP session will likely be disconnected and RDP to the VM won't work until rebooted.*
    1. Reboot Admin-PC from the Azure Portal
    1. Reconnect to Admin-PC and domain join it to the contoso.com domain
1. Follow the process oulined in the [Alert Lab](https://docs.microsoft.com/en-us/defender-for-identity/playbook-setup-lab#-base-lab-environment) beginning with the **Configure SAM-R capabilities from ContosoDC**

## VMs Created
VM Name | Operating Sytem | IP Address | VM Size | Scheduled Shutdown
------- | --------------- | ---------- | ------- | ------------------
ContosoDC1 | Windows Server 2012 R2 | 10.0.24.4 | Basic_A2 | 7PM EST
Victim-PC | Windows 10 | 10.0.24.5 | Basic_A2 | 7PM EST
Admin-PC | Windows 10 | 10.0.24.6 | Basic_A2 | 7PM EST

## Accounts and Groups Created
The deployment script and Active Directory DSC script set up the following accounts and groups for use with the Security Alert Lab
Account | From | OU | Details
------- | ---- | -- | -------
labadmin | deployment script | Users | This is the admin setup account on all VMs created
jeffl | AD DSC | LabUsers | Jeff Leatherman Account from Alert Lab
ronhd | AD DSC | LabUsers | Ron HelpDesk account from Alert Lab
samiraa | AD DSC | LabUsers | Samira Abbasi account from Alert Lab
aatpservice | AD DSC | LabUsers | Defender for Identity Service Acount
Helpdesk | AD DSC | LabUsers | Security Group which ronhd is member
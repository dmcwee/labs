# LABS
This project is a collection of labs that I use for testing and learning tools like MDI, MDE, ADFS, and others.  I'm sharing this so others can also use these labs to quickly establish learning environments.

## Network Philosophy
Although Azure does provide Just-In-Time access to VMs I've taken the approach that none of the VMs created in the labs have public IP addresses.  This will help protect the machines in environments where JIT access isn't available/enabled.  However, as a result when the network is provisioned a Point-to-Site gateway is created and adding a VPN connection from your machine to the environment is required.

### VPN Set-Up
To support the Point-to-Site VPN a root and child certificate is needed for authentication. Use the following steps to generate the certificate.

**Note:** The script is unsigned so you will need to run this in an environment that allows for unsigned script execution.

1. Download the [New-P2SCertificate.ps1](./common/scripts/New-P2SCertificate.ps1) script to your machine
1. Run:
```
PS> New-P2SCertificate.ps1 [optional: -RootCertCN myrootcert] [optional: -ChildCertCN mychildcert] [optional: -CertOutputFile pubrootcert.txt]
```
1. Copy the output in the terminal, or the output in the txt file generated and provide this as the *gatewayRootCert* parameter in the lab provisioning process or in the Gateway's Settings (post provisioning).
1. After the Root Certificate has been applied to the gateway's configuration go to the *Point-to-Site Configuration* and choose *Download VPN client*
1. Extract the file from the downloaded Zip and install the appropriate VPN agent (typically WindowsAmd64)

# !!! Alert !!!

**NOTE:**
This repository is being restructured so that different scenarios I use will be hosted in folder here rather than having different projects on GitHub.  There will likely be broken parts while this happens so if you find errors please let me know, using the reporting in GitHub.

## Restructure Plan
1. Move root project to Federation so it will create a DC, ADFS, WAP, and Client VM as well as the usual private network and Point-to-Site VPN capability.
1. Keep AzATP_Lab as is since it is based on the MDI lab and deploys easily.
1. Add a MDE Lab that will deploy VMs of multiple types (Windows Server 2012 R2 - 2019+, Windows 10+, and Linux)
1. Add a SCI Lab that will be associated with the [SCI Learning Project](https://github.com/dmcwee/sci) for internal and external use

## Other changes
[] Update templates to point to the correct locations for the lab DSCs if appropriate
[] Update templates to include a 'Lab' tag when deploying so resources can be deployed to the same resource group but filtered easily
[] Update templates to use the same networking configurations, but different subnets
[] Break up common parts of templates into 'Shared' JSON files vs. the unique parts kept in each sub folder
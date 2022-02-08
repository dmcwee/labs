# LABS

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
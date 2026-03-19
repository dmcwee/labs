# Defender Lab

This lab deploys a multi-machine Active Directory environment for Microsoft Defender testing and evaluation.

## Deploy

There are a few templates you can use along with the attack labs.

### MDE template (Well Tested)

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fgithub%2Ecom%2Fdmcwee%2Flabs%2Fblob%2Fpublished%2Fpub%2FMDELab%2Fmdelab%2Ejson)

### MDI Template (Well Tested)

This template only deploys two domain controllers for testing of parallel sub-domain monitoring with MDI.

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fgithub%2Ecom%2Fdmcwee%2Flabs%2Fblob%2Fpublished%2Fpub%2FMDILab%2Fmdilab%2Ejson)

### Unified Teamplate (In Development)

> **Note:** This template uses 12 `Standard DSv3 Family vCPUs` which generally exceeds the default regional quota. Therefore, you should [request a quota increase](https://portal.azure.com/#view/Microsoft_Azure_Capacity/QuotaMenuBlade/~/myQuotas) for your desired deployment region before attempting to run this deployment. [MS Learn](https://learn.microsoft.com/en-us/azure/quotas/per-vm-quota-requests)

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw%2Egithubusercontent%2Ecom%2Fdmcwee%2Flabs%2Frefs%2Fheads%2Fpublished%2Fdev%2FDefender%2Flab%2Ejson)

#### Parameters

| Parameter | Default | Description |
|---|---|---|
| `username` | `cmadmin` | Local admin username |
| `password` | *(secure)* | Admin password |
| `domainName` | `mcweeinc.com` | Root AD domain |
| `domainNetbiosName` | `mcwee` | Root domain NetBIOS name |
| `subDomain` | `tech.mcweeinc.com` | Child AD domain |
| `subDomainNetbiosName` | `tech` | Child domain NetBIOS name |
| `size` | `Standard_B2ms` | VM size |

## Machines

| Name | OS | Private IP | Role |
|---|---|---|---|
| LabAd | Windows Server 2022 Datacenter | 10.0.2.5 | Domain Controller (`mcweeinc.com`) |
| LabSubAd | Windows Server 2022 Datacenter | 10.0.2.6 | Sub-Domain Controller (`tech.mcweeinc.com`) |
| WinClient11 | Windows 11 23H2 Enterprise | 10.0.2.40 | Client (badClient – attack staging) |
| Win2016 | Windows Server 2016 Datacenter | 10.0.2.50 | Lab Server |
| Win2022 | Windows Server 2022 Datacenter | 10.0.2.51 | Lab Server |
| LinuxUbuntu | Ubuntu 22.04 LTS | 10.0.2.52 | Lab Server |

## Post-Deployment Configuration

### Domain Controllers (LabAd / LabSubAd)

The `DcSetup.ps1` custom script extension installs AD DS, promotes the server to a domain controller, and stages `DcHydrate.ps1` in `c:\hydration\` to run on next reboot.

### WinClient11 (badClient)

The `badClientSetup` custom script extension downloads `run-victimpc.ps1` and stages it in `c:\hydration\`.

## User Accounts (created by DcHydrate.ps1)

The domain hydration script creates the following accounts in the **LabUsers** OU:

| Display Name | SAM Account Name | UPN | Group Memberships |
|---|---|---|---|
| John Smith | jsmith | jsmith@\<domain\> | *(none)* |
| Jeff Leatherman | jeffl | jeffl@\<domain\> | *(none)* |
| Ron HelpDesk | ronhd | ronhd@\<domain\> | Helpdesk |
| John Admin | johna | johna@\<domain\> | Domain Admins |
| Samira Abbasi | samiraa | samiraa@\<domain\> | Domain Admins |
| Admin Backup | admin_bak | admin\_bak@\<domain\> | Remote IT Admin, Admin Backup |

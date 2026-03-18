# Defender for Identity Security Alert Lab

This is a Azure Resource Manager deployment template for the Defender for Identity. This lab is designed to support the Defender for Identity [Security Alert lab](https://microsoft.github.io/TechExcel-Defender-for-Identity/).

## Quick Deploy

Currently, this template deploys two domain controllers for testing of parallel sub-domain monitoring with MDI.

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fgithub%2Ecom%2Fdmcwee%2Flabs%2Fblob%2Fpublished%2Fpub%2FMDILab%2Fmdilab%2Ejson)

### Parameters

| Parameter | Default | Description |
|---|---|---|
| `username` | *(required)* | Local admin username |
| `password` | *(secure)* | Admin password |
| `subDomain1` | `mayor.mcweeinc.com` | First child AD domain |
| `netbiosName1` | `mayor` | First child domain NetBIOS name |
| `subDomain2` | `tech.mcweeinc.com` | Second child AD domain |
| `netbiosName2` | `tech` | Second child domain NetBIOS name |
| `size` | `Standard_B2ms` | VM size |

### Machines

| Name | OS | Private IP | Role |
|---|---|---|---|
| LabSubAd1 | Windows Server 2022 Datacenter | 10.0.2.15 | Domain Controller (`mayor.mcweeinc.com`) |
| LabSubAd2 | Windows Server 2022 Datacenter | 10.0.2.16 | Domain Controller (`tech.mcweeinc.com`) |
| Win2022 | Windows Server 2022 Datacenter | 10.0.2.50 | Lab Server |
| WinClient11 | Windows 11 23H2 Enterprise | 10.0.2.51 | Client (badClient – attack staging) |

## Post-Deployment Configuration

### Domain Controllers (LabSubAd1 / LabSubAd2)

The `DcSetup.ps1` custom script extension installs AD DS, promotes each server to a domain controller for its respective sub-domain, and stages `DcHydrate.ps1` in `c:\hydration\` to run on next reboot.

### WinClient11 (badClient)

The `badClientSetup` custom script extension downloads `run-victimpc.ps1` and stages it in `c:\hydration\`.

## User Accounts (created by DcHydrate.ps1)

The domain hydration script creates the following accounts in the **LabUsers** OU on each domain controller:

| Display Name | SAM Account Name | UPN | Group Memberships |
|---|---|---|---|
| John Smith | jsmith | jsmith@\<domain\> | *(none)* |
| Jeff Leatherman | jeffl | jeffl@\<domain\> | *(none)* |
| Ron HelpDesk | ronhd | ronhd@\<domain\> | Helpdesk |
| John Admin | johna | johna@\<domain\> | Domain Admins |
| Samira Abbasi | samiraa | samiraa@\<domain\> | Domain Admins |
| Admin Backup | admin_bak | admin\_bak@\<domain\> | Remote IT Admin, Admin Backup |


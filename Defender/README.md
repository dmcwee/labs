# Unified Defender Lab

This **preview / in-development** lab deploys six machines for combined Microsoft
Defender learning and testing. The tables below describe the current
[Bicep source](modules/lab.bicep) and its shared modules, not a newly verified
deployment. Published templates and downloaded setup scripts may differ from
this checkout.

<a id="deploy"></a>

## Quick Deploy

### Unified template (In Development)

<a id="unified-teamplate-in-development"></a>

Choose Azure CLI or the portal button. Both use the same published preview
template; use the same parameter values and target resource group for equivalent
deployments.

### Azure CLI

With Azure CLI signed in to the intended subscription, run interactively against
an existing, dedicated lab resource group and supply required parameters when prompted:

```powershell
az deployment group create --resource-group "<lab-resource-group>" --template-uri "https://raw.githubusercontent.com/dmcwee/labs/refs/heads/published/dev/Defender/lab.json"
```

### Deploy to Azure

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fdmcwee%2Flabs%2Frefs%2Fheads%2Fpublished%2Fdev%2FDefender%2Flab.json)

Both options retain the development-template destination. All lab source now
selects `VpnGw1AZ`, but this preview URL requires a new `dev` publication after
the source change is merged there; see
[deployment differences](../docs/deployment-alignment.md). Check regional
availability, image compatibility, costs, and VM-family quota before deployment.
All six VMs default to `Standard_B2ms`; the quota required depends on the `size`
you select, not a fixed DSv3 configuration.

### MDE template (Well Tested)

For the specialized endpoint environment, see the [MDE lab guide](../MDELab/README.md).
The existing guide labels this template well tested; this documentation update
does not establish a new deployment verification.

Use that guide's Quick Deploy command or Deploy to Azure button for the MDE
environment, not the unified command above.

### MDI Template (Well Tested)

The specialized [MDI lab](../MDILab/README.md) deploys two domain controllers,
one member-server candidate, and one client. Its guide also retains the existing
well-tested designation.

Use that guide's Quick Deploy command or Deploy to Azure button for the MDI
environment, not the unified command above.

<a id="parameters"></a>

## Deployment parameters

These ten string parameters apply to the **unified** Bicep template. Required
values have no default; empty VPN certificate values are accepted but do not
configure certificate-based client access.

| Parameter | Default | Description |
| --- | --- | --- |
| `username` | `cmadmin` | Administrator username for every VM; minimum 3 characters. |
| `password` | Required; secure | Administrator password for every VM; meet Azure VM requirements and keep it out of tracked parameter files. |
| `gatewayCertData` | Required; empty string allowed | Base64 public root certificate data for the VPN gateway, not a private key or PFX. |
| `gatewayCertName` | Required; empty string allowed | Name assigned to the VPN root certificate. |
| `domainName` | `mcweeinc.com` | Forest/domain DNS name created on `LabAd`; minimum 3 characters. |
| `domainNetbiosName` | `mcwee` | NetBIOS name for the `LabAd` domain; minimum 3 characters. |
| `subDomain` | `tech.mcweeinc.com` | Forest/domain DNS name created on `LabSubAd`; minimum 3 characters. Despite the parameter name, setup does not create an AD child domain. |
| `subDomainNetbiosName` | `tech` | NetBIOS name for the `LabSubAd` domain; minimum 3 characters. |
| `size` | `Standard_B2ms` | VM size applied to all six machines; minimum 1 character. |
| `setupFilePaths` | `https://raw.githubusercontent.com/dmcwee/labs/refs/heads/published/pub/DSC` | Base URL for the three setup scripts downloaded by VM extensions; minimum 1 character. |

<a id="machines"></a>

## Deployed machines

All VMs use the resource group's region, the supplied `size`, static private IPs,
and `Standard_LRS` managed OS disks. Images default to version `latest`.

| Machine | Operating system | Image SKU | Private IP | Purpose and automatic configuration |
| --- | --- | --- | --- | --- |
| `LabAd` | Windows Server 2022 Datacenter | `2022-Datacenter` | `10.0.2.5` | Domain controller for `domainName`; receives the AD setup extension. |
| `LabSubAd` | Windows Server 2022 Datacenter | `2022-Datacenter` | `10.0.2.6` | Domain controller for `subDomain`; receives a separate AD setup extension. |
| `WinClient11` | Windows 11 23H2 Enterprise | `win11-23h2-ent` | `10.0.2.40` | Client; the extension stages `run-victimpc.ps1` without executing it. |
| `Win2016` | Windows Server 2016 Datacenter | `2016-Datacenter` | `10.0.2.50` | Windows server for lab scenarios. |
| `Win2022` | Windows Server 2022 Datacenter | `2022-Datacenter` | `10.0.2.51` | Windows server for lab scenarios. |
| `LinuxUbuntu` | Ubuntu Server 22.04 LTS | `22_04-lts-gen2` | `10.0.2.52` | Linux server for lab scenarios. |

Windows Server images use publisher/offer `MicrosoftWindowsServer/WindowsServer`;
the client uses `microsoftwindowsdesktop/windows-11`; Ubuntu uses
`canonical/0001-com-ubuntu-server-jammy`. The
[shared VM module](../Common/modules/virtualMachine.bicep) creates one NIC and
one managed OS disk per VM, plus enabled daily shutdown at **19:00,
`Eastern Standard Time`**, with notifications disabled.

## Network and access

The [shared network module](../Common/modules/network.bicep) creates:

| Component | Configuration |
| --- | --- |
| Virtual network | `10.0.0.0/16`. |
| `client-subnet` | `10.0.2.0/24`; contains all six VM NICs. |
| `GatewaySubnet` | `10.0.100.0/24`. |
| DNS servers | `10.0.2.5` and Azure-provided `168.63.129.16`. |
| NAT gateway | Standard NAT gateway and static Standard public IP for client-subnet outbound access. |
| VPN gateway | Target: route-based `VpnGw1AZ`, `Generation1`, and a separate static Standard public IP. The preview deployment options require updated `dev` artifacts to be published first. |
| Point-to-site clients | `10.10.10.0/24`, SSTP, certificate authentication. |

VM NICs have no public IPs. Configure VPN access to reach their private addresses.
Both certificate parameters must be non-empty to import a root certificate; the
[certificate helper](../Common/scripts/New-P2SCertificate.ps1) is a Windows example.
VM shutdown does not remove billable gateways, disks, or public IPs.

## Post-deployment configuration

### Domain controllers

Each AD extension downloads `DcSetup.ps1` and `DcHydrate.ps1` from `setupFilePaths`.
The [setup script](../Common/DSC/DcSetup.ps1) calls `Install-ADDSForest` separately
on each controller. **It does not create a parent/child AD relationship or trust**
between the domains, even when their DNS names share a suffix.

Setup installs AD DS and DNS and stages hydration in `C:\hydration` with a RunOnce
entry for execution after restart and sign-in. Verify completion before using
the accounts or running scenarios.

### Client and remaining servers

The client extension only stages `run-victimpc.ps1` in `C:\hydration`. It does not
run the script or join the machine to a domain. The current source script refers
to `Contoso` accounts and changes protection settings; review it against your
isolated lab before any manual use. The remaining servers receive their OS images
without domain-join or Defender-onboarding automation.

### User Accounts (created by DcHydrate.ps1)

When hydration completes, it creates the following users in each domain's
`LabUsers` OU. UPNs use the account name and that domain's DNS name.

| Display name | Account name | Additional groups assigned by hydration |
| --- | --- | --- |
| John Smith | `jsmith` | None. |
| Jeff Leatherman | `jeffl` | None. |
| Ron HelpDesk | `ronhd` | Helpdesk. |
| John Admin | `johna` | Domain Admins. |
| Samira Abbasi | `samiraa` | Domain Admins. |
| Admin Backup | `admin_bak` | Remote IT Admin; Admin Backup. |

New hydrated users receive the deployment `password`; existing account passwords
are not reset. The VM `username` defaults to `cmadmin`; on unjoined Windows
members, sign in as `.\cmadmin` with the supplied password. Override that name
when you change the deployment parameter. Default domain identities include
`mcwee\jsmith` / `mcwee\johna` on `LabAd`, and `tech\jsmith` / `tech\johna`
on `LabSubAd`, after hydration and the required membership/access configuration.

### Reusing scenario guides

Use this deployment's machine table when following the standalone MDE/MDI
instructions. `WinClient11` here is `10.0.2.40`, not either standalone lab's
client address. MDE domain steps can use `LabAd` (`10.0.2.5`,
`mcweeinc.com` / `mcwee`). For MDI first-forest examples, replace
`LabSubAd1` with `LabAd`, `mayor.mcweeinc.com` with `mcweeinc.com`, and `mayor`
with `mcwee`. For second-forest examples, replace `LabSubAd2` with `LabSubAd`
(`10.0.2.6`); the default domain/prefix remain `tech.mcweeinc.com` / `tech`.
Configure DNS, domain membership, tools, and sensor onboarding for the selected
forest rather than assuming those steps or a trust already exist.

## Next steps

Read [Getting started](../docs/getting-started.md) for prerequisites, costs,
onboarding considerations, and teardown. Use the [MDE](../MDELab/Attacks/README.md)
or [MDI](../MDILab/Attacks/README.md) scenario guides only after checking their
machine, domain, and product requirements against this preview environment.
No Defender sensor onboarding or attack execution is performed by this template.

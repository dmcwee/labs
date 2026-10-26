# Defender for Endpoint Security Lab

This lab deploys a five-machine Azure environment for testing Microsoft Defender
for Endpoint (MDE) scenarios, including onboarding, offboarding, device
configuration, and monitoring.

## Quick Deploy

Choose Azure CLI or the portal button. Both use the same published MDE template;
use the same parameter values and target resource group for equivalent deployments.

### Azure CLI

With Azure CLI signed in to the intended subscription, run interactively against
an existing, dedicated lab resource group and supply required parameters when prompted:

```powershell
az deployment group create --resource-group "<lab-resource-group>" --template-uri "https://raw.githubusercontent.com/dmcwee/labs/refs/heads/published/pub/MDELab/mdelab.json"
```

### Deploy to Azure

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fdmcwee%2Flabs%2Frefs%2Fheads%2Fpublished%2Fpub%2FMDELab%2Fmdelab.json)

The details below describe the current [MDE Bicep source](modules/mdelab.bicep)
and its shared modules. All lab source now selects `VpnGw1AZ`; the published
templates must be rebuilt after this change is merged. Until then both options
above still use the previous publication. See
[deployment differences](../docs/deployment-alignment.md) for publication status
and outstanding script-channel corrections.

## Deployment parameters

All seven parameters are strings. Parameters without defaults must be supplied
when deploying.

| Parameter | Default | Description |
| --- | --- | --- |
| `username` | `cmadmin` | Administrator username used when creating each VM. Minimum 3 characters. |
| `password` | Required; secure | Administrator password used when creating each VM. Supply a password that meets Azure VM requirements; do not commit it to a parameter file. |
| `gatewayCertData` | Required; empty string allowed | Base64-encoded public root certificate data for point-to-site VPN authentication, not a private key or PFX. |
| `gatewayCertName` | Required; empty string allowed | Name assigned to the VPN root certificate. |
| `domainName` | `mcweeinc.com` | AD forest/domain DNS name created on `LabAd`. Minimum 3 characters. |
| `domainNetbiosName` | `mcwee` | NetBIOS name for the AD domain. Minimum 3 characters. |
| `size` | Required; no default | Azure VM size applied to all five machines. Minimum 1 character; choose an available size compatible with the images and your regional quota. |

The network module imports a VPN root certificate only when both
`gatewayCertName` and `gatewayCertData` are non-empty. Empty values do not disable
creation of the VPN gateway, but they leave it without a configured root
certificate for client authentication. The
[certificate helper](../Common/scripts/New-P2SCertificate.ps1) provides an example
of generating a root certificate and its Base64 public certificate data on Windows.

## Deployed machines

All five VMs are placed in the resource group's Azure region, use the supplied
`size`, and have statically assigned private IP addresses in `client-subnet`.
Their managed OS disks use `Standard_LRS`. Image versions default to `latest`.

| Machine | Operating system | Image SKU | Private IP | Purpose and automatic configuration |
| --- | --- | --- | --- | --- |
| `LabAd` | Windows Server 2022 Datacenter | `2022-Datacenter` | `10.0.2.5` | Domain controller; a custom script extension installs AD DS and DNS and creates the configured forest/domain. |
| `Win2016` | Windows Server 2016 Datacenter | `2016-Datacenter` | `10.0.2.50` | Windows server for lab scenarios. |
| `Win2022` | Windows Server 2022 Datacenter | `2022-Datacenter` | `10.0.2.51` | Windows server for lab scenarios. |
| `LinuxUbuntu` | Ubuntu Server 22.04 LTS | `22_04-lts-gen2` | `10.0.2.52` | Linux server for MDE learning and testing. |
| `WinClient11` | Windows 11 23H2 Enterprise | `win11-23h2-ent` | `10.0.2.53` | Windows client for lab scenarios. |

Windows Server images use publisher `MicrosoftWindowsServer` and offer
`WindowsServer`. Ubuntu uses publisher `canonical` and offer
`0001-com-ubuntu-server-jammy`; the Windows client uses publisher
`microsoftwindowsdesktop` and offer `windows-11`.

The [shared VM module](../Common/modules/virtualMachine.bicep) creates one network
interface and one managed OS disk per VM. It also creates an enabled daily
shutdown schedule for each machine at **19:00 in `Eastern Standard Time`** (the
Azure time-zone identifier), with shutdown notifications disabled.

## Network and access

The [shared network module](../Common/modules/network.bicep) also deploys the
following resources; they are additional to the five VMs.

| Component | Configuration |
| --- | --- |
| Virtual network | Address space `10.0.0.0/16`. |
| `client-subnet` | `10.0.2.0/24`; contains all five VM network interfaces. |
| `GatewaySubnet` | `10.0.100.0/24`. |
| DNS servers | `10.0.2.5` (`LabAd`) and `168.63.129.16` (Azure-provided DNS). |
| NAT gateway | Standard NAT gateway with a static Standard public IP for outbound connectivity from `client-subnet`. |
| VPN gateway | Target: route-based `VpnGw1AZ`, `Generation1`, with a separate static Standard public IP. The published-template options require the updated artifacts to be published first. |
| Point-to-site clients | Address pool `10.10.10.0/24`, SSTP, certificate authentication. |

VM network interfaces do not receive public IP addresses from this template.
Use an appropriately configured VPN connection to access their private IPs.
The gateways and public IPs are billable resources; VM auto-shutdown does not
remove them.

## Post-deployment configuration

Only `LabAd` receives the AD setup extension in this template. It downloads
`DcSetup.ps1` and `DcHydrate.ps1` from the existing `published/dev/DSC` asset path.
The setup script installs AD DS and DNS, promotes the machine to a domain
controller, and stages `DcHydrate.ps1` in `C:\hydration` with a RunOnce entry for
hydration after restart and sign-in.

The other four VMs are provisioned from their OS images. This Bicep template does
not automatically join them to the domain, onboard devices to MDE, or execute
attack scenarios. Complete the configuration and product onboarding required by
your chosen scenario before running it.

### Accounts and scenario sign-in

For an unjoined Windows member VM such as `WinClient11`, use `.\cmadmin`
and the deployment `password` unless you overrode `username`. The same username
and supplied password are provisioned on `LinuxUbuntu`. These are OS
administrator credentials, not automatically configured domain sign-ins on
member machines.

When [DcHydrate.ps1](../Common/DSC/DcHydrate.ps1) completes on `LabAd`, it
creates these accounts in the domain's `LabUsers` OU:

| Display name | Account name | Additional groups assigned by hydration |
| --- | --- | --- |
| John Smith | `jsmith` | None. |
| Jeff Leatherman | `jeffl` | None. |
| Ron HelpDesk | `ronhd` | Helpdesk. |
| John Admin | `johna` | Domain Admins. |
| Samira Abbasi | `samiraa` | Domain Admins. |
| Admin Backup | `admin_bak` | Remote IT Admin; Admin Backup. |

New hydrated users receive the deployment `password`; existing account passwords
are not reset. Default domain sign-ins include `mcwee\jsmith` and `mcwee\johna`,
or `jsmith@mcweeinc.com` and `johna@mcweeinc.com`. If you override either domain
parameter, update these identities accordingly. See
[scenario setup](Attacks/README.md#before-running-a-scenario) for which account,
host, and manual configuration each kind of scenario needs.

## Next steps

Review [Getting started](../docs/getting-started.md) for deployment preparation,
onboarding considerations, and teardown guidance. Then choose an
[MDE scenario](Attacks/README.md), checking its prerequisites and cleanup steps
before running scripts.

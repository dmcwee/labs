# Defender for Identity Security Alert Lab

This four-machine environment supports Microsoft Defender for Identity (MDI)
learning and the [Security Alert lab](https://microsoft.github.io/TechExcel-Defender-for-Identity/).
The details below describe the current [Bicep source](modules/mdilab.bicep) and its
shared modules. Published templates and downloaded scripts may differ until
rebuilt or updated from this checkout.

## Quick Deploy

Choose Azure CLI or the portal button. Both use the same published MDI template;
use the same parameter values and target resource group for equivalent deployments.

### Azure CLI

With Azure CLI signed in to the intended subscription, run interactively against
an existing, dedicated lab resource group and supply required parameters when prompted:

```powershell
az deployment group create --resource-group "<lab-resource-group>" --template-uri "https://raw.githubusercontent.com/dmcwee/labs/refs/heads/published/pub/MDILab/mdilab.json"
```

### Deploy to Azure

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fdmcwee%2Flabs%2Frefs%2Fheads%2Fpublished%2Fpub%2FMDILab%2Fmdilab.json)

All lab source now selects `VpnGw1AZ`; the published templates must be rebuilt
after merge. Both options above use the same publication, which is not updated
by local edits alone. Review the
[deployment differences](../docs/deployment-alignment.md), regional VM availability,
image compatibility, licensing, quota, and expected costs before deployment.

<a id="parameters"></a>

## Deployment parameters

All nine parameters are strings. Required values have no default.

| Parameter | Default | Description |
| --- | --- | --- |
| `username` | Required | Administrator username for all four VMs; minimum 3 characters. |
| `password` | Required; secure | Administrator password for all four VMs; meet Azure VM requirements and keep it out of tracked parameter files. |
| `gatewayCertData` | Required; empty string allowed | Base64 public root certificate data for point-to-site VPN authentication, not a private key or PFX. |
| `gatewayCertName` | Required; empty string allowed | Name assigned to the VPN root certificate. |
| `subDomain1` | `mayor.mcweeinc.com` | Forest/domain DNS name created on `LabSubAd1`; minimum 3 characters. |
| `subDomain2` | `tech.mcweeinc.com` | Forest/domain DNS name created on `LabSubAd2`; minimum 3 characters. |
| `netbiosName1` | `mayor` | NetBIOS name for the first domain; minimum 3 characters. |
| `netbiosName2` | `tech` | NetBIOS name for the second domain; minimum 3 characters. |
| `size` | `Standard_B2ms` | Azure VM size applied to all four machines. |

Despite the `subDomain` parameter names, the current setup creates independent
forests, not child domains of an existing `mcweeinc.com` forest.

<a id="machines"></a>

## Deployed machines

All VMs use the resource group's region, the supplied `size`, static private IPs,
and `Standard_LRS` managed OS disks. Image versions default to `latest`.

| Machine | Operating system | Image SKU | Private IP | Purpose and automatic configuration |
| --- | --- | --- | --- | --- |
| `LabSubAd1` | Windows Server 2022 Datacenter | `2022-Datacenter` | `10.0.2.15` | Domain controller for `subDomain1`; receives an AD setup extension. |
| `LabSubAd2` | Windows Server 2022 Datacenter | `2022-Datacenter` | `10.0.2.16` | Domain controller for `subDomain2`; receives a separate AD setup extension. |
| `Win2022` | Windows Server 2022 Datacenter | `2022-Datacenter` | `10.0.2.50` | Windows server for lab scenarios; not automatically domain-joined. |
| `WinClient11` | Windows 11 23H2 Enterprise | `win11-23h2-ent` | `10.0.2.51` | Client; an extension stages `run-victimpc.ps1` without executing it. |

Server images use publisher/offer `MicrosoftWindowsServer/WindowsServer`; the
client uses `microsoftwindowsdesktop/windows-11`. The
[shared VM module](../Common/modules/virtualMachine.bicep) creates one NIC and one
managed OS disk per machine, plus enabled daily shutdown at **19:00,
`Eastern Standard Time`**, with notifications disabled.

## Network and access

The [shared network module](../Common/modules/network.bicep) creates:

| Component | Configuration |
| --- | --- |
| Virtual network | `10.0.0.0/16`. |
| `client-subnet` | `10.0.2.0/24`; contains all four VM NICs. |
| `GatewaySubnet` | `10.0.100.0/24`. |
| DNS servers | `10.0.2.15` and Azure-provided `168.63.129.16`. |
| NAT gateway | Standard NAT gateway and static Standard public IP for client-subnet outbound access. |
| VPN gateway | Target: route-based `VpnGw1AZ`, `Generation1`, and a separate static Standard public IP. The published-template options require the updated artifacts to be published first. |
| Point-to-site clients | `10.10.10.0/24`, SSTP, certificate authentication. |

VM NICs have no public IPs. Both certificate parameters must be non-empty to
import a root certificate for VPN client access; empty values do not omit the
gateway. The [certificate helper](../Common/scripts/New-P2SCertificate.ps1) is a
Windows example. VM shutdown does not remove billable gateways, disks, or public IPs.

## Post-deployment configuration

### Domain Controllers (LabSubAd1 / LabSubAd2)

Each controller downloads `DcSetup.ps1` and `DcHydrate.ps1` from source
`dev/Common/DSC`. The [setup script](../Common/DSC/DcSetup.ps1) calls
`Install-ADDSForest` independently on each machine: **no parent/child AD
relationship or inter-forest trust is configured**.

Setup installs AD DS and DNS and stages hydration in `C:\hydration` with a RunOnce
entry for execution after restart and sign-in. Check provisioning and hydration
completion before relying on the accounts.

### WinClient11 (badClient)

The extension downloads `run-victimpc.ps1` from `published/dev/DSC` and stages it
in `C:\hydration`; it does not execute it or join the client to a domain. The
current source script uses `Contoso` account names and changes protection settings.
Review and adapt it for your isolated lab before any manual use. `Win2022` has no
additional setup extension in this template.

### User Accounts (created by DcHydrate.ps1)

When hydration completes, it creates these users in the `LabUsers` OU on each
domain. UPNs use the account name and that domain's DNS name.

| Display name | Account name | Additional groups assigned by hydration |
| --- | --- | --- |
| John Smith | `jsmith` | None. |
| Jeff Leatherman | `jeffl` | None. |
| Ron HelpDesk | `ronhd` | Helpdesk. |
| John Admin | `johna` | Domain Admins. |
| Samira Abbasi | `samiraa` | Domain Admins. |
| Admin Backup | `admin_bak` | Remote IT Admin; Admin Backup. |

New hydrated accounts receive the deployment `password`; passwords of existing
accounts are not reset. The VM administrator uses the required `username`
parameter, which has no default. On unjoined Windows member VMs, sign in as
`.\<deployment-username>` with that supplied password.

With default domain parameters, scenario domain accounts include
`mayor\jsmith` and `mayor\johna` in the first forest, or `tech\jsmith` and
`tech\johna` in the second. UPN suffixes are `mayor.mcweeinc.com` and
`tech.mcweeinc.com`, respectively. Use the
[scenario account and machine context](Attacks/README.md) instead of unrelated
`CONTOSO`/`DC01` examples; replace domain values if you overrode them at deployment.

## Next steps

Review [Getting started](../docs/getting-started.md) for prerequisites, onboarding
considerations, costs, and teardown. Complete the domain-joining, MDI sensor
installation, and tenant configuration required by your chosen
[MDI scenario](Attacks/README.md). This template does not automatically onboard
Defender sensors or run attack scenarios.

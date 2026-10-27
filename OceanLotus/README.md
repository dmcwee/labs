# OceanLotus Lab

This three-machine infrastructure environment deploys a Windows Server host,
Ubuntu, and Kali Linux. This guide describes the current
[Bicep source](modules/OceanLotus.bicep) and its shared modules; it does not add
an attack walkthrough or establish successful deployment or Defender compatibility.

## Quick Deploy

Choose Azure CLI or the portal button. Both use the same published OceanLotus
template; use the same parameter values and target resource group for equivalent
deployments.

### Azure CLI

With Azure CLI signed in to the intended subscription, run interactively against
an existing, dedicated lab resource group and supply required parameters when prompted:

```powershell
az deployment group create --resource-group "<lab-resource-group>" --template-uri "https://raw.githubusercontent.com/dmcwee/labs/refs/heads/published/pub/OceanLotus/OceanLotus.json"
```

### Deploy to Azure

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fdmcwee%2Flabs%2Frefs%2Fheads%2Fpublished%2Fpub%2FOceanLotus%2FOceanLotus.json)

Check regional image availability,
VM-size compatibility, quota, licensing, and costs first. Kali specifies an Azure
Marketplace plan; review its terms and any required subscription acceptance
before deployment. Do not put administrator passwords in shell commands or
tracked parameter files.

The folder also contains a [generated ARM snapshot](OceanLotus.json) and
[parameter example](parameters/OceanLotus.parameters.json). They are reference
artifacts, not proof that a published deployment matches the current Bicep.
See [deployment differences](../docs/deployment-alignment.md) for the distinction
between published templates, local Bicep, and checked-in generated snapshots.
OceanLotus now inherits the shared `VpnGw1AZ` default, and its checked-in ARM
snapshot has been regenerated from current source. The published URL still
requires updated artifacts after merge.

## Deployment parameters

All five parameters are strings. Required values have no default.

| Parameter | Default | Description |
| --- | --- | --- |
| `password` | Required; secure | Administrator password for all three VMs; meet Azure VM requirements and keep it private. |
| `username` | Required | Administrator username for all three VMs. |
| `gatewayCertData` | Required; empty string allowed | Base64 public root certificate data for the VPN gateway, not a private key or PFX. |
| `gatewayCertName` | Required; empty string allowed | Name assigned to the VPN root certificate. |
| `size` | `Standard_B1ms` | Azure VM size applied to all three machines. |

## Deployed machines

All VMs use the resource group's region, the supplied `size`, static private IPs,
and `Standard_LRS` managed OS disks. Image versions default to `latest`.

| Machine | Operating system | Image SKU | Private IP | Purpose and automatic configuration |
| --- | --- | --- | --- | --- |
| `vhagar` | Windows Server 2019 Datacenter | `2019-DataCenter` | `10.90.30.20` | Windows host; OS provisioning only. |
| `drogon` | Ubuntu Server 22.04 LTS | `22_04-lts-gen2` | `10.90.30.7` | Linux host; OS provisioning only. |
| `kali` | Kali Linux image | `kali-2024-4` | `10.90.30.26` | Kali host; VM includes the matching Marketplace plan. |

Image publisher/offer pairs are `MicrosoftWindowsServer/WindowsServer`,
`canonical/0001-com-ubuntu-server-jammy`, and `kali-linux/kali`, respectively.
The Kali plan is publisher `kali-linux`, product `kali`, name `kali-2024-4`.
All three machines receive the tag `ExcludeMdeAutoProvisioning: 'True'`;
the template does not itself onboard MDE or prove how external automation handles
that tag.

The [shared VM module](../Common/modules/virtualMachine.bicep) creates one NIC and
one managed OS disk per VM. It enables Linux boot diagnostics and password
authentication on Linux. Daily shutdown is enabled at **19:00,
`Eastern Standard Time`**, with notifications disabled.

## Network and access

This template overrides several [shared network](../Common/modules/network.bicep)
defaults:

| Component | Configuration |
| --- | --- |
| Virtual network | `10.90.0.0/16`. |
| `client-subnet` | `10.90.30.0/24`; contains all three VM NICs. |
| `GatewaySubnet` | `10.90.100.0/24`. |
| DNS servers | Azure-provided `168.63.129.16`. |
| NAT gateway | Standard NAT gateway and static Standard public IP for client-subnet outbound access. |
| VPN gateway | Target: route-based `VpnGw1AZ`, `Generation1`, and a separate static Standard public IP. Updated artifacts must be published before the command/button options use this SKU. |
| Point-to-site clients | `10.10.10.0/24`, IKEv2, certificate authentication. |

VM NICs have no public IPs. Configure an IKEv2-compatible VPN client to reach the
private addresses. Both certificate parameters must be non-empty to import a
root certificate; empty values do not omit the gateway. The
[certificate helper](../Common/scripts/New-P2SCertificate.ps1) is a Windows example.
VM shutdown does not remove billable gateways, disks, or public IPs.

## Post-deployment configuration

This Bicep provisions OS images and shared infrastructure only. It does not
configure Active Directory, join domains, install Defender sensors, stage attack
scripts, or execute scenarios. Review and complete any intended tool installation,
tenant configuration, and onboarding separately in an isolated environment.

### Accounts and scenario sign-in

Use the required deployment `username` and `password` on all three hosts; there
is no default username. For RDP to `vhagar` (`10.90.30.20`), sign in as
`.\<deployment-username>`. For SSH to `drogon` (`10.90.30.7`) or `kali`
(`10.90.30.26`), use that same supplied Linux username, not an assumed image
default. No domain users or scenario-specific accounts are created. See the
[OceanLotus scenario context](Scenarios/README.md) for matching connection
examples and preparation.

## Next steps

Review [Getting started](../docs/getting-started.md) for prerequisites, safe lab
use, and teardown. The [scenario context](Scenarios/README.md) documents the
deployment's identities and hosts, but no OceanLotus-specific attack walkthrough
is supplied. Do not assume that the [MDE](../MDELab/Attacks/README.md) or
[MDI](../MDILab/Attacks/README.md) scenarios work unchanged on these machines.

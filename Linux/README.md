# Linux Lab

The current [Bicep source](modules/linux.bicep) deploys **two Linux VMs**: Ubuntu
22.04 LTS and SUSE Linux Enterprise Server 12 SP5. It supports Linux learning and
MDE onboarding/configuration exercises; it does not deploy CentOS or install MDE.

The Quick Deploy command and portal button below both select the published
two-machine Bicep-generated template, not this folder's older four-machine ARM
entrypoint.

## Quick Deploy

Choose Azure CLI or the portal button; use the same parameter values and target
resource group for equivalent deployments.

### Azure CLI

With Azure CLI signed in to the intended subscription, run interactively against
an existing, dedicated lab resource group and supply required parameters when prompted:

```powershell
az deployment group create --resource-group "<lab-resource-group>" --template-uri "https://raw.githubusercontent.com/dmcwee/labs/refs/heads/published/pub/Linux/linux.json"
```

### Deploy to Azure

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fdmcwee%2Flabs%2Frefs%2Fheads%2Fpublished%2Fpub%2FLinux%2Flinux.json)

All lab source now selects `VpnGw1AZ`; the published templates must be rebuilt
after merge. Both options above use the same publication, which is not updated
by local edits alone. Check regional image availability,
size compatibility, quota, licensing, and expected costs first. See
[deployment differences](../docs/deployment-alignment.md) for that pending source
update and the comparison with the previous [ARM entrypoint](azuredeploy.json).
This documentation change has not performed an Azure deployment.

## Deployment parameters

The current Bicep template has five string parameters. Required values have no default.

| Parameter | Default | Description |
| --- | --- | --- |
| `username` | Required | Administrator username for both VMs; minimum 3 characters. |
| `password` | Required; secure | Administrator password for both VMs; meet Azure VM requirements and keep it out of tracked parameter files. |
| `gatewayCertData` | Required; empty string allowed | Base64 public root certificate data for the VPN gateway, not a private key or PFX. |
| `gatewayCertName` | Required; empty string allowed | Name assigned to the VPN root certificate. |
| `size` | `Standard_B1ms` | Azure VM size applied to both machines. |

## Deployed machines

The **current Bicep** deploys the following machines in the resource group's
region, with the supplied `size`, static private IPs, `Standard_LRS` managed OS
disks, and image version `latest`.

| Machine | Operating system | Image SKU | Private IP | Purpose and automatic configuration |
| --- | --- | --- | --- | --- |
| `LinuxUbuntu` | Ubuntu Server 22.04 LTS | `22_04-lts-gen2` | `10.0.2.50` | General Linux and MDE learning; OS provisioning only. |
| `LinuxSuseOs1` | SUSE Linux Enterprise Server 12 SP5 | `gen2` | `10.0.2.51` | SUSE Linux and MDE learning; OS provisioning only. |

Ubuntu uses publisher/offer `canonical/0001-com-ubuntu-server-jammy`; SUSE uses
`suse/sles-12-sp5-basic`. Verify current product support before choosing an image
for MDE evaluation.

The [shared VM module](../Common/modules/virtualMachine.bicep) creates one NIC and
one managed OS disk per machine, enables Linux boot diagnostics, and permits
password authentication. Daily shutdown is enabled at **19:00,
`Eastern Standard Time`**, with notifications disabled.

## Network and access

The **Bicep** [shared network module](../Common/modules/network.bicep) creates:

| Component | Configuration |
| --- | --- |
| Virtual network | `10.0.0.0/16`. |
| `client-subnet` | `10.0.2.0/24`; contains both VM NICs. |
| `GatewaySubnet` | `10.0.100.0/24`. |
| DNS servers | Azure-provided `168.63.129.16`; no AD domain controller is deployed. |
| NAT gateway | Standard NAT gateway and static Standard public IP for client-subnet outbound access. |
| VPN gateway | Target: route-based `VpnGw1AZ`, `Generation1`, and a separate static Standard public IP. The published-template options require the updated artifacts to be published first. |
| Point-to-site clients | `10.10.10.0/24`, SSTP, certificate authentication. |

VM NICs have no public IPs. Both certificate values must be non-empty to import a
VPN root certificate; empty values do not omit the gateway. The
[certificate helper](../Common/scripts/New-P2SCertificate.ps1) is a Windows example.
VM shutdown does not remove billable gateways, disks, or public IPs.

## Post-deployment configuration

The Bicep deployment installs neither MDE nor an administration toolchain and
does not execute scenarios. After verifying the selected distributions are
supported, complete your tenant-specific onboarding and configuration.

The repository contains [Ansible examples](../MDELab/Ansible) and
[SaltStack examples](../MDELab/SaltStack) for review; they are not automatically
applied or guaranteed to support every image above.

### Accounts and scenario sign-in

Use the required deployment `username` and `password` for the local Linux account
on `LinuxUbuntu` (`10.0.2.50`) or `LinuxSuseOs1` (`10.0.2.51`); there is no
default username. No AD domain users or scenario accounts are provisioned. The
[Linux scenario context](Scenarios/README.md) gives matching SSH examples,
machine roles, and prerequisites without assuming the Windows MDE scripts apply.

## Next steps

Read [Getting started](../docs/getting-started.md) for prerequisites, costs, and
teardown. Explore [scheduling scripts](../MDELab/Scripts/README.md) and the
[offline update container](../MDELab/Offline/README.Docker.md) after checking their
requirements. Remove the dedicated lab resources when finished.

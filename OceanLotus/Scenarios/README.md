# OceanLotus Lab Scenarios

## Deployment context

This context matches the three-VM [OceanLotus deployment](../README.md) and its
[Bicep entrypoint](../modules/OceanLotus.bicep). It documents the hosts and accounts
available for a separately prepared exercise; **there is no OceanLotus-specific
attack walkthrough or automated adversary emulation in this repository**.
Check [publication status](../../docs/deployment-alignment.md) and actual
provisioning before choosing a host.

## Accounts and sign-in

The `username` and `password` deployment parameters are required. There is
**no default administrator username**. Use the supplied credentials for the
local administrator on `vhagar` and the local Linux account on `drogon` and
`kali`. In a Windows RDP sign-in, use `.\<deployment-username>` with your actual
parameter value; do not assume a `kali` username just because a VM is named `kali`.
No AD domain, hydrated domain users, or scenario accounts are created.

Use your own authorized tenant account for Azure and Defender portal access.
The local VM credentials do not create cloud identities or grant tenant roles.

From a PowerShell terminal on a VPN-connected workstation:

```powershell
$labUsername = Read-Host "Enter the username supplied at deployment"
ssh "${labUsername}@10.90.30.7"
```

Use `10.90.30.26` for the Kali VM instead. For Windows, connect with RDP to
`10.90.30.20` and enter the deployment credentials interactively.

## Machines and roles

These are VM names and the computer names requested by the shared VM module;
verify the actual OS hostname after connecting.

| Machine | Operating system | Image SKU | Private IP | Scenario role |
| --- | --- | --- | --- | --- |
| `vhagar` | Windows Server 2019 Datacenter | `2019-DataCenter` | `10.90.30.20` | Windows host; no domain controller, sensor onboarding, or scenario setup is included. |
| `drogon` | Ubuntu Server 22.04 LTS | `22_04-lts-gen2` | `10.90.30.7` | Ubuntu host; select and configure a role for your isolated exercise. |
| `kali` | Kali Linux image | `kali-2024-4` | `10.90.30.26` | Kali host; its name does not imply credentials, connectivity, or a preconfigured attack role. |

## Before running a scenario

Connect with an IKEv2-compatible client to the lab's point-to-site VPN; the VM
NICs do not have public IPs. Confirm the host with `hostname` or
`$env:COMPUTERNAME` and the account with `whoami`. The `10.90.30.0/24` client
subnet is different from the other labs' `10.0.2.0/24` subnet.

This deployment provisions OS images and networking only. Review image/tool
support, install and configure any intended tools or sensors, and establish
your authorized source/target roles before an exercise. The
`ExcludeMdeAutoProvisioning` tag is set to `True`; do not assume external
automation will onboard these machines.

## Scenarios

No OceanLotus execution procedure is currently supplied. The
[MDE](../../MDELab/Attacks/README.md) and
[MDI](../../MDILab/Attacks/README.md) guides describe different environments.
Their hosts, domains, accounts, prerequisites, and Windows versions do not
transfer automatically to `vhagar`, `drogon`, or `kali`. This context page
does not claim those scenarios have been validated here.

## Cleanup

Use the cleanup instructions for the exercise you selected, removing only its
temporary resources and accounts. Keep the deployment administrator available
until teardown. Follow [lab teardown guidance](../../docs/getting-started.md)
when finished with the dedicated resource group; shutting down VMs does not
remove the billable network infrastructure or disks.

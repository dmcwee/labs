# Linux Lab Scenarios

## Deployment context

This context matches the two-VM [Linux deployment](../README.md) and its
[Bicep entrypoint](../modules/linux.bicep), not the older four-VM ARM example.
It provides the identities and hosts to use for Linux learning and onboarding
exercises; it does not claim a Linux attack walkthrough is already implemented.
Check [publication status](../../docs/deployment-alignment.md) and the actual
deployment before using any example.

## Accounts and sign-in

The `username` and `password` deployment parameters are required. There is
**no default administrator username**. The chosen `username` is a local Linux
account on both machines; use its supplied password for SSH and, when prompted,
authorized `sudo` operations. Do not assume `cmadmin` or `root` is the deployment
sign-in. No AD domain, domain users, or scenario accounts are created.

Azure deployment and Defender portal access require your own authorized tenant
account; local Linux credentials do not provide tenant roles.

From a PowerShell terminal on a VPN-connected workstation:

```powershell
$labUsername = Read-Host "Enter the username supplied at deployment"
ssh "${labUsername}@10.0.2.50"
```

Use `10.0.2.51` instead to connect to `LinuxSuseOs1`. The examples prompt for the
username so they do not invent a parameter default or expose a password.

## Machines and roles

These are VM names and the computer names requested by the shared VM module;
verify the actual OS hostname after connecting.

| Machine | Operating system | Image SKU | Private IP | Scenario role |
| --- | --- | --- | --- | --- |
| `LinuxUbuntu` | Ubuntu Server 22.04 LTS | `22_04-lts-gen2` | `10.0.2.50` | Ubuntu learning and supported MDE onboarding/configuration exercises. |
| `LinuxSuseOs1` | SUSE Linux Enterprise Server 12 SP5 | `gen2` | `10.0.2.51` | SUSE learning; verify current product support before MDE exercises. |

## Before running a scenario

Connect through the lab's SSTP point-to-site VPN; neither VM has a public IP.
After SSH sign-in, use `hostname` and `whoami` to confirm the host and account.
The images are provisioned without MDE, domain joining, an automation controller,
or automatically executed scenarios. Verify distribution support, install and
onboard the required product, and check device health before testing detection.
These are not the MDE lab's `LinuxUbuntu` (`10.0.2.52`) or its Windows machines.

## Scenarios

Start with [Ansible examples](../../MDELab/Ansible) or
[SaltStack examples](../../MDELab/SaltStack) only after checking image support,
installing the necessary tools, and replacing inventory hosts and login users
with the machines and deployment username above. Neither tool is preconfigured
by this template. These are configuration examples, not verified walkthroughs
for both deployed distributions.

The [MDE Windows attack scenarios](../../MDELab/Attacks/README.md) are not Linux
instructions and should not be run unchanged on these hosts.

## Cleanup

Review the cleanup for any tool or exercise you actually used. Remove only
resources and accounts created for that exercise; retain the deployment
administrator while the lab is in use. When finished, follow
[lab teardown guidance](../../docs/getting-started.md) for the dedicated resource
group. VM shutdown alone does not remove billable disks and gateways.

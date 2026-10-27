# Deployment entry points and known differences

Each deployable lab has an Azure CLI Quick Deploy command and a **Deploy to Azure**
button. Both select the **same published ARM template URL**. With the same
subscription/resource group, parameter values, and template revision, they request
the same resources. The portal can create a resource group; the CLI examples
assume one already exists. Neither option automatically runs attack scenarios.

Quick Deploy deliberately uses `--template-uri`, not `--template-file`: building
local Bicep can differ from deploying an older published template. No repository
checkout is required for the published-template commands. These are moving branch
URLs; for reproducibility, pin both entry points to the same commit or release,
including runtime script assets.

## Selected templates

All paths below are relative to the `published` branch in `dmcwee/labs`.

| Lab | Command and button target | VM count | Channel |
| --- | --- | --- | --- |
| [MDE](../MDELab/README.md) | `pub/MDELab/mdelab.json` | 5 | Published `pub`. |
| [MDI](../MDILab/README.md) | `pub/MDILab/mdilab.json` | 4 | Published `pub`. |
| [Unified Defender](../Defender/README.md) | `dev/Defender/lab.json` | 6 | Preview; preserves the existing `dev` selection. |
| [Linux](../Linux/README.md) | `pub/Linux/linux.json` | 2 | Published `pub`; replaces the former four-machine ARM button target. |
| [OceanLotus](../OceanLotus/README.md) | `pub/OceanLotus/OceanLotus.json` | 3 | Published `pub`; both entry points are now provided. |

## Entry-point differences corrected in the guides

| Lab | Previous mismatch | Documentation correction |
| --- | --- | --- |
| MDE and MDI | Only portal buttons were supplied, using GitHub `blob` URLs. | Added CLI commands and made both options use the same raw published template URLs. |
| Unified Defender | Its page offered three different environment buttons without a matching CLI command. | Added one command/button pair for unified Defender; specialized MDE/MDI choices link to their own guides and matching entry points. |
| Linux | CLI compiled the local two-VM Bicep; the portal button selected `dev/Linux/azuredeploy.json`, a different four-VM linked-template deployment. | Both now use `published/pub/Linux/linux.json`, as selected by the repository owner. |
| OceanLotus | CLI compiled local Bicep; no portal button was provided. | Added a command/button pair using the existing published ARM artifact. |

The previous Linux file remains in the repository as source history/reference.
It is not the target of either primary Linux deployment option.

## Remaining source and publication differences

These findings were checked against published snapshot
[`5c8be28`](https://github.com/dmcwee/labs/tree/5c8be28e33e87aa9cf353e288582d5407137a546).
Its commit message identifies source commit
[`a71b24f`](https://github.com/dmcwee/labs/commit/a71b24f506e1a273afba27a72ba54c08f0cf6db2).
The initial source comparison identified the shared gateway default changing
from `VpnGw1` to `VpnGw1AZ`. The gateway update now also removes OceanLotus's
non-AZ override and regenerates its checked-in ARM snapshot from current Bicep.
All five lab entrypoints now inherit the shared `VpnGw1AZ` default.

The selected public template URLs were readable and their parameter contracts,
machine definitions, gateway defaults, and runtime script references were inspected.
This is not an Azure deployment, what-if result, or end-to-end provisioning test.
Recheck these findings after republishing.

| Area | Source status and inspected publication | Remaining action |
| --- | --- | --- |
| Gateway SKU across all labs | All five entrypoints inherit `VpnGw1AZ` from [shared Bicep](../Common/modules/network.bicep). The inspected published snapshot still selects `VpnGw1`. | Merge and publish updated source to each required channel, then verify its generated gateway SKU. Local edits do not update the command/button URLs. |
| Publisher triggers and validation | The [Bicep publisher](../.github/workflows/main.yml) now watches `Common/modules`, its own workflow, and infrastructure checks as well as lab Bicep and DSC files. It compiles and checks gateway SKUs before publishing, supports manual dispatch on `dev`/`master`, and serializes writes to `published` across both source branches. | Merge the workflow changes. Publish `master` to refresh `pub`, and publish updated `dev` source separately to refresh `dev`. |
| OceanLotus ARM snapshot | Its [entrypoint](../OceanLotus/modules/OceanLotus.bicep) no longer overrides the shared SKU, and the [checked-in snapshot](../OceanLotus/OceanLotus.json) has been regenerated with `VpnGw1AZ`. | Publish the rebuilt artifact. Regeneration also incorporates existing shared-network NAT configuration and gateway naming absent from the older snapshot; review that full diff before redeploying an existing environment. |
| MDE runtime scripts | The `pub` template downloads AD setup/hydration scripts from `published/dev/DSC`. | Publish and reference a coherent template/script bundle rather than mixing stable and development paths. |
| MDI runtime scripts | The `pub` template downloads AD scripts directly from source `dev/Common/DSC`, and the client script from `published/dev/DSC`. | Align both script locations with the intended published template channel or immutable bundle. |
| Unified Defender runtime scripts | The selected template is `published/dev`, but `setupFilePaths` defaults to `published/pub/DSC`. | Decide and document the preview asset channel, then set the asset root consistently when publishing. Keep the parameter available for intentional overrides. |

At the inspected snapshot, each lab's `pub` and `dev` ARM files have identical
Git blob hashes. This does not make their moving URLs interchangeable: a later
publication can change one channel independently, and script URLs remain separate.

### Publishing the gateway update

After merging the source and workflow changes into `master`, a matching push
rebuilds all lab templates under `published/pub`. Merge the same source changes
into `dev` and publish there to refresh `published/dev`, including the unified
Defender preview URL. Updating `master` alone does not refresh that preview.
The workflow can also be run manually on either updated source branch.

The infrastructure checks compile all five labs and the three shared-module
examples, verify the effective gateway SKU name and tier, and check the tracked
OceanLotus snapshot. Run them locally with Azure CLI and Bicep installed:

```powershell
python -m unittest discover -s tests\infrastructure
```

These changes update deployment definitions, not running Azure gateways. Assess
the supported SKU migration or replacement process before redeploying an existing
environment; changing a template is not proof that an in-place upgrade is safe.

### Previous Linux ARM contract

The former button selected `dev/Linux/azuredeploy.json`. Its live definition
requests four VMs and accepts these parameters, rather than the current five-string
Bicep contract:

| Parameter | Default | Description |
| --- | --- | --- |
| `storageType` | `Standard_LRS` | Storage type passed to the linked VM template. |
| `subNetRangeOctet` | `2` | Integer used in the subnet and VM private IP addresses. |
| `gatewayCertName` | Empty string | Public root certificate name. |
| `gatewayCertData` | Empty string | Public root certificate data. |
| `userName` | `cmadmin` | Administrator username; differs from Bicep `username`. |
| `password` | Required; secure | Administrator password. |
| `CommonTemplateUri` | `https://raw.githubusercontent.com/dmcwee/labs/master/Common` | Base URL for linked ARM templates. |

### Previous Linux ARM inventory

With default `subNetRangeOctet=2`, that template requests:

| Machine | Operating system | Image SKU | Requested private IP |
| --- | --- | --- | --- |
| `LinuxManager` | Ubuntu Server 22.04 LTS | `22_04-lts-gen2` | `10.0.2.30` |
| `LinuxUbuntu1` | Ubuntu Server 22.04 LTS | `22_04-lts-gen2` | `10.0.2.31` |
| `LinuxUbuntu2` | Ubuntu Server 22.04 LTS | `22_04-lts-gen2` | `10.0.2.32` |
| `LinuxSuseOs1` | SUSE Linux Enterprise Server 12 SP5 | `gen2` | `10.0.2.33` |

It also requests subnet `mdeNet` and gateway range `10.0.10.0/24`, unlike the
current Bicep's `client-subnet` and `10.0.100.0/24`. Its default linked
`Common/network.json`, `subnet.json`, `p2sGateway.json`, and `linux.json` URLs
returned HTTP 404 when inspected. Linked VM sizing and other missing-template
behavior cannot be established from the old entrypoint alone.

The two-VM published Bicep-generated artifact is now the Linux command/button
target. Retiring the old source file or redirecting other external consumers is
a separate compatibility decision; it has not been deleted or republished here.

## Maintaining parity

When changing a lab's selected template, update the command and button together.
The documentation checks decode the portal URL and compare it with the CLI's
`--template-uri` in both source and rendered guides. The checks run offline;
live artifact freshness, runtime script availability, and Azure deployability
require separate verification.

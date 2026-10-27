# LABS

This project is a collection of labs that I use for testing and learning tools like MDI, MDE, ADFS, and others.  I'm sharing this so others can also use these labs to quickly establish learning environments.

Use this catalog directly on GitHub or through the documentation site at
**[davidmcwee.com/labs/](https://davidmcwee.com/labs/)** once the initial Pages
deployment is enabled. Both views use the same guides.

Start with [Getting started](docs/getting-started.md) for the deployment,
scenario, and cleanup workflow. Use only isolated, authorized lab environments:
some scenarios make destructive changes or disable protections.

## Lab environments

| Environment | Guide | Status and purpose |
| --- | --- | --- |
| Defender for Endpoint | [MDE lab](MDELab/README.md) | Existing deployment, described as well tested in the Defender guide; endpoint learning and testing. |
| Defender for Identity | [MDI lab](MDILab/README.md) | Existing deployment, described as well tested in the Defender guide; identity alert scenarios. |
| Unified Defender | [Unified lab](Defender/README.md) | Preview / in development; combined multi-machine environment. |
| Linux | [Linux lab](Linux/README.md) | Linux learning and MDE testing; see the guide for the existing deployment target. |
| OceanLotus | [OceanLotus lab](OceanLotus/README.md) | Infrastructure reference: Windows Server, Ubuntu, and Kali; no scenario walkthrough is provided. |

Each lab guide provides an Azure CLI Quick Deploy command and Deploy to Azure
button that select the same published template. See
[deployment entry points and known differences](docs/deployment-alignment.md)
for the Linux target correction and remaining source/publication drift.
The documentation does not establish new deployment or scenario compatibility claims.

## Execution scenarios

- [Defender for Endpoint scenarios](MDELab/Attacks/README.md)
- [Defender for Identity scenarios](MDILab/Attacks/README.md)
- [Linux scenario context](Linux/Scenarios/README.md) (accounts, hosts, and configuration prerequisites)
- [OceanLotus scenario context](OceanLotus/Scenarios/README.md) (deployment preparation; no attack walkthrough)
- [ASR sample scripts](ASR) (source examples; no walkthrough is currently provided)

Read the chosen scenario's prerequisites, expected results, and cleanup guidance
before running scripts. Obtain sibling scripts together when using a scenario runner.

## Tools and reference assets

- [MDE scheduling scripts](MDELab/Scripts/README.md)
- [MDE offline update container](MDELab/Offline/README.Docker.md)
- [Defender policy settings](MDELab/Policy/Policies.md) and [policy JSON examples](Policies)

## Legacy and external resources

- [AzATP lab](AzATP_Lab/README.md): previous name; now points to the MDI lab.
- [Advanced Hunting](AdvancedHunting/README.md): moved to a dedicated repository.
- [Live Response](LiveResponse/README.md): moved to a dedicated repository.
- [Federation](Federation/README.md): older lab; recommends Microsoft's AD FS deployment guidance.

## Documentation contributions

See [Documentation preview and publishing](docs/publishing.md) to build the site
locally, add guides, and enable GitHub Pages at `/labs/` without changing the
existing root-domain site.
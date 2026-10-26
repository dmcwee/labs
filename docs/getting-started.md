# Getting started

These environments are for isolated learning and testing, not production use.
Scenario scripts may change permissions, remove data, disable protections, or
disrupt machines. Read each scenario before downloading or running its scripts.
Publishing this documentation does not execute any scenarios.

## Choose an environment

| Environment | Start here | Next step |
| --- | --- | --- |
| Defender for Endpoint | [MDE deployment](../MDELab/README.md) | [MDE scenarios](../MDELab/Attacks/README.md) |
| Defender for Identity | [MDI deployment](../MDILab/README.md) | [MDI scenarios](../MDILab/Attacks/README.md) |
| Unified Defender | [Unified deployment (preview)](../Defender/README.md) | Confirm the topology and prerequisites for the scenario you intend to use. |
| Linux | [Linux deployment](../Linux/README.md) | [Scheduling examples](../MDELab/Scripts/README.md) or [offline updates](../MDELab/Offline/README.Docker.md) |
| OceanLotus | [OceanLotus deployment](../OceanLotus/README.md) | Infrastructure reference only; no OceanLotus-specific execution guide is included. |

The existing guides describe the MDE and MDI deployments as well tested and the
unified deployment as in development. This documentation site does not establish
new compatibility or testing claims.

## Deploy and configure

1. Read the environment guide, machine topology, parameters, and post-deployment steps.
2. Confirm your Azure subscription, permissions, regional VM availability, quota,
   and expected costs. Confirm the product licensing and onboarding requirements
   for the features you intend to evaluate.
3. Choose the environment guide's Azure CLI Quick Deploy command or Deploy to
   Azure button. Both select the same published template; supply the same
   parameters for equivalent resources. Review the
   [known source/publication differences](deployment-alignment.md), including the
   pending gateway-SKU update; this documentation does not correct the publisher.
4. Use a dedicated lab resource group, keep credentials private, and complete
   provisioning and product onboarding before starting scenarios.

## Follow a scenario

Use the relevant scenario index to choose an exercise. Check its machine, account,
privilege, and product requirements against the environment you deployed; not every
exercise is verified for every environment. Read the full guide, including
expected telemetry and cleanup instructions, before executing anything.

Download links point to source files in the repository, not executable web pages.
Some runners require sibling scripts: obtain the complete relevant directory
through a repository checkout or archive rather than downloading only the runner.
Review scripts locally and run them only on systems you own or are authorized to test.

## Inspect results and clean up

Follow the scenario's verification and cleanup instructions where provided.
Detection availability and timing depend on onboarding, configuration, and the
product features enabled in your tenant. Do not treat a missing alert as proof
that the script succeeded or failed.

If cleanup is not documented or the exercise makes destructive changes, use a
disposable environment and rebuild it rather than assuming it can be reset.
When finished, remove the dedicated lab resources you created and check for
remaining billable resources. Remove only resources you have confirmed belong
to this lab.

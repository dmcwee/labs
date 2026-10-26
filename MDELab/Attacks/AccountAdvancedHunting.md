# Account Advanced Hunting

> **Lab context:** On standalone MDE, start on `WinClient11` (`10.0.2.53`)
> using deployment `username` (`.\cmadmin` by default) and the supplied
> `password`. See [scenario setup and domain accounts](README.md#before-running-a-scenario)
> before domain-dependent steps; domain joining and MDE onboarding are manual.

## Overview

Use Advanced Hunting to correlate creation of a disposable local account with
its addition to the local Administrators group. This manual exercise demonstrates
account persistence and a custom detection workflow on the deployed MDE client.

## MITRE ATT&CK Mapping

| Tactic | Technique | ID |
| -- | -- | -- |
| Persistence | Create Account: Local Account | T1136.001 |
| Persistence | Account Manipulation | T1098 |
| Privilege Escalation | Account Manipulation | T1098 |

## Attack Simulation

### Prerequisites

- Onboarded, healthy MDE sensor on `WinClient11` (`10.0.2.53`).
- An elevated Command Prompt using the deployment administrator
  (`.\cmadmin` by default) for local account and group changes.
- Authorized Defender tenant access to Advanced Hunting, and permission to
  manage custom detections if completing that optional part of the exercise.
- A new, disposable local account name, `MdeHuntingTest`, that does not already
  exist. It is not the deployment administrator or a hydrated domain account.

### What the Exercise Does

1. Creates a disposable local user and adds it to local Administrators.
2. Finds the related account events and correlates them in Advanced Hunting.
3. Optionally creates a custom detection for the correlated activity.
4. Removes the account and any exercise-specific detection or response actions.

This is a manual walkthrough, not a parameterized repository PowerShell script.
The linked [CreateAccount.cmd example](https://github.com/dmcwee/AdvancedHunting/blob/main/CreateAccount/CreateAccount.cmd)
is external reference material; the commands below define the disposable account
used in this guide.

## Setup

Complete the [shared scenario setup](README.md#before-running-a-scenario).
On `WinClient11`, verify `hostname` and `whoami`, then open an elevated Command
Prompt. Check existing accounts and local Administrators membership before
changing anything:

```cmd
net user
net localgroup Administrators
```

If `MdeHuntingTest` already exists, stop and choose a different disposable name
throughout the exercise. Record the device, actor, baseline membership, and start
time. Open Advanced Hunting in the Defender portal using your authorized tenant
account; local administrator permissions do not grant portal access.

## Scenario Execution

<a id="scenario"></a>

### Steps: Create User

Create the disposable account using a new lab-only password entered
interactively, then add it to the local group:

```cmd
net user MdeHuntingTest * /add
net localgroup Administrators MdeHuntingTest /add
net localgroup Administrators
```

Confirm that only the intended account was added before continuing.

### Advanced Hunting

In Advanced Hunting, use the source device and recorded time window when walking
through the query examples. Inspect the account-creation and group-addition
events before assuming the correlation succeeded.

1. Start by finding all account events [Query 1](https://github.com/dmcwee/AdvancedHunting/blob/main/CreateAccount/CreateAccount-Query1.kql)
1. Reduce results to just Account Creation & Account Added to Local Group [Query 2](https://github.com/dmcwee/AdvancedHunting/blob/main/CreateAccount/CreateAccount-Query2.kql)
1. Reduce our initial results to just account created and get select fields. We will merge this into a single line with the Account added to group events shortly. Note: AccountSid in this event refers to the account created SID [Query 3](https://github.com/dmcwee/AdvancedHunting/blob/main/CreateAccount/CreateAccount-Query3.kql)
1. Assign the results of the query to a scalar variable and add back the query for Account Added events as well as extending the query by parsing the JSON in the Additional Fields column to extract Group Name [Query 4](https://github.com/dmcwee/AdvancedHunting/blob/main/CreateAccount/CreateAccount-Query4.kql)
1. Next merge the scalar value and query using an inner join. You can now see when the account was created and when it was added to the local group. [Query 5](https://github.com/dmcwee/AdvancedHunting/blob/main/CreateAccount/CreateAccount-Query5.kql)
1. Extend the query by calculating the time difference between when the account was created and when it was added to the local group. Also, reduce the output fields to just those we want to see: Created, Added, Account Name, Local Group, Device Id, Device Name, Created By [Query 6](https://github.com/dmcwee/AdvancedHunting/blob/main/CreateAccount/CreateAccount-Query6.kql)
1. Finally filter out the default addition to the local Users group and review the final query's entity and event fields for the custom detection. [Query Final](https://github.com/dmcwee/AdvancedHunting/blob/main/CreateAccount/CreateAccount-QueryFinal.kql)

### Create Custom Detection

1. From the Advanced Hunting page for the above final query choose the Manage rules and select Create custom detection
1. Provide Alert DetailsDetection Name: User Created and Added to Sensitive group
    1. Frequency: Hourly
    1. Alert Title: User Created and Added to Sensitive group
    1. Severity: High
    1. Category: Persistence
    1. MITRE Techniques: Select the relevant techniques from the mapping above, such as T1136.001 and T1098.
    1. Description: Alert when a new user is created and then added to a local privileged group.
    1. Recommended Actions: Review the account created to ensure it is a valid account and should have permission granted.
1. Impacted Entities
    1. Device: DeviceId
    1. User: InitiatingProcessAccountObjectId
1. Actions (Optional - Just showing these settings is fine and then demonstrate the alert being created)
    1. Devices: Choose an action to perform - Isolate device (Full) or Restrict app execution are good options for demonstration
    1. User: Mark user as compromised
        > The user account that was used to create the account is the account that will be Marked As Compromised
    1. Save the Custom Alert

The example uses an hourly detection. Do not describe it as near-real-time;
available frequencies and supported query features depend on the tenant and rule.

## Expected Alerts

### Expected Output

Successful local commands create `MdeHuntingTest` and list it in local
Administrators. With sensor telemetry available, the hunting queries should
identify the account-creation and group-addition events for the same device and
account. Verify the actual rows, identities, and timestamps rather than assuming
that a command's success guarantees collected telemetry.

### Custom Detection

An enabled rule matching the observed events may produce the configured
**User Created and Added to Sensitive group** alert. A built-in alert is not
required for this exercise. Custom alert availability and timing depend on query
results, rule configuration, execution frequency, and telemetry ingestion.
Keep automated isolation, app restrictions, and account response actions
optional and approved for the lab.

## Why Does This Matter

1. **Correlation** connects two separate events into a persistence signal.
2. **Identity attribution** distinguishes the actor from the account receiving
   elevated permissions.
3. **Detection validation** separates local execution, telemetry, query matches,
   and an actual custom alert.

## Best Practices

1. Use only a new disposable local account and a unique lab-only password.
2. Scope hunting queries to the intended device and time window.
3. Validate query results and entity mappings before enabling response actions.
4. Keep tenant permissions separate from local administration privileges.
5. Record exercise-specific rules and actions so they can be removed at cleanup.

## Clean-Up

<a id="cleanup"></a>

After collecting the account events, remove only the local user created for
this exercise with `net user MdeHuntingTest /delete`. Remove or disable any
custom detection and response actions you enabled specifically for this test.
Do not delete the deployment administrator or the hydrated domain accounts.

## References

<a id="queries"></a>

### Queries

* [Query 1](https://github.com/dmcwee/AdvancedHunting/blob/main/CreateAccount/CreateAccount-Query1.kql)
* [Query 2](https://github.com/dmcwee/AdvancedHunting/blob/main/CreateAccount/CreateAccount-Query2.kql)
* [Query 3](https://github.com/dmcwee/AdvancedHunting/blob/main/CreateAccount/CreateAccount-Query3.kql)
* [Query 4](https://github.com/dmcwee/AdvancedHunting/blob/main/CreateAccount/CreateAccount-Query4.kql)
* [Query 5](https://github.com/dmcwee/AdvancedHunting/blob/main/CreateAccount/CreateAccount-Query5.kql)
* [Query 6](https://github.com/dmcwee/AdvancedHunting/blob/main/CreateAccount/CreateAccount-Query6.kql)
* [Query Final](https://github.com/dmcwee/AdvancedHunting/blob/main/CreateAccount/CreateAccount-QueryFinal.kql)

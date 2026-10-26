# Suspicious Account Addition

> **Lab context:** Use `WinClient11` (`10.0.2.51`) and target
> `LabSubAd1` (`10.0.2.15`) in the default `mayor.mcweeinc.com` forest.
> Use `mayor\johna` for these privileged AD steps after verifying hydration.
> Complete the [scenario setup](README.md#before-running-a-scenario) first;
> the disposable `bad.user` is not a deployment or hydrated account.

## Overview

This scenario adds a disposable domain account to a sensitive group such as
`Domain Admins`, illustrating account manipulation for persistence or privilege
escalation. The script can create the test account if needed, remove its group
membership, and optionally delete it during cleanup.

MDI may detect unusual additions to sensitive groups. This script changes one
account's membership in one selected group per invocation; it does not add
multiple accounts to multiple groups in a single run.

## MITRE ATT&CK Mapping

| Tactic | Technique | ID |
| -- | -- | -- |
| Persistence | Account Manipulation | T1098 |
| Privilege Escalation | Account Manipulation | T1098 |
| Persistence | Create Account: Domain Account (with `-CreateUser`) | T1136.002 |

## Attack Simulation

### Prerequisites

- Prepared, domain-joined `WinClient11` with Windows PowerShell and the Active
  Directory PowerShell module (`RSAT-AD-PowerShell`).
- Connectivity to the selected domain's controllers, including AD Web Services
  used by the Active Directory cmdlets.
- A verified domain identity such as `mayor\johna` with permission to create the
  test account and change the selected group's membership. Local elevation or
  Account Operators membership alone does not grant permission to manage
  protected groups such as Domain Admins.
- A new, disposable account name for this exercise. Hydration does not create
  `bad.user`; verify that it does not already exist before using `-CreateUser`.
- A healthy MDI sensor on the controller and appropriate Defender portal access
  if evaluating detections.

This is a privileged directory change. The script does not ask for confirmation
before adding group membership, and its deletion cleanup suppresses confirmation.
Never target the deployment administrator, hydrated users, or an unrelated
existing account.

### Script: Invoke-SuspiciousAccountAddition.ps1

Use [Invoke-SuspiciousAccountAddition.ps1](./Invoke-SuspiciousAccountAddition.ps1)
to manage the scenario account and membership.

#### Parameters

| Parameter | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `-UserName` | String | No | `bad.user` | Account whose membership is changed. Use only the disposable scenario account. |
| `-DomainGroup` | String | No | `Domain Admins` | One group to modify; use the same value for cleanup. |
| `-CreateUser` | Switch | No | Not set | Creates the account only if it does not exist; otherwise reuses the existing account without resetting its password. |
| `-Password` | String | No | `P@ssw0rd123!` | Password used for a new account. The script accepts a plain string and prints the password after creation; use a unique lab-only value. |
| `-Cleanup` | Switch | No | Not set | Removes membership in the selected group instead of adding it. |
| `-DeleteUser` | Switch | No | Not set | Also deletes the account when used with `-Cleanup`; has no deletion effect on its own. |

#### What the Script Does

1. Imports the Active Directory module and discovers the current domain with
   `Get-ADDomain`.
2. Finds the selected account, creating it only when absent and `-CreateUser`
   is supplied.
3. Finds the selected group and checks its direct membership.
4. Adds the account unless already a direct member, or removes membership when
   `-Cleanup` is used.
5. Deletes the account only when both `-Cleanup` and `-DeleteUser` are supplied.

The script does not provide controller, domain, or credential parameters.
Operations use the current domain context and Windows identity, not a
controller selected by a command-line option.

## Setup

Complete the [shared scenario setup](README.md#before-running-a-scenario).
Download [Invoke-SuspiciousAccountAddition.ps1](./Invoke-SuspiciousAccountAddition.ps1)
and open Windows PowerShell in its directory as the authorized domain account.

Before making changes, verify the current identity, domain, existing account,
and baseline group membership:

```powershell
whoami
Import-Module ActiveDirectory
Get-ADDomain | Select-Object DNSRoot, PDCEmulator
Get-ADUser -Filter 'SamAccountName -eq "bad.user"'
Get-ADGroupMember -Identity "Domain Admins" | Select-Object SamAccountName
```

For the first-forest exercise, confirm `mayor\johna` and
`mayor.mcweeinc.com`. If `bad.user` already exists and was not created solely
for this exercise, stop and select a different disposable name throughout.

For the independent second forest, use its prepared client/domain context and
an authorized identity such as `tech\johna`, then verify
`tech.mcweeinc.com` before execution. First-forest permissions do not
automatically apply there.

### Usage Examples

#### Create the disposable account and add it to Domain Admins

After confirming that `bad.user` does not already exist, choose a new lab-only
password interactively:

```powershell
$credential = Get-Credential -UserName "bad.user@mayor.mcweeinc.com" -Message "Choose a new password for the disposable lab account"
$accountParameters = @{
    UserName = "bad.user"
    DomainGroup = "Domain Admins"
    CreateUser = $true
    Password = $credential.GetNetworkCredential().Password
}
.\Invoke-SuspiciousAccountAddition.ps1 @accountParameters
```

The prompt collects a password for the new account; the script still executes
under the authorized administrator's Windows identity. The password must satisfy
the domain's password policy. Although the example avoids a literal password in
the command, the script prints it after account creation; do not expose the
console or its transcript, and do not reuse a deployment or hydrated password.

#### Add the same scenario account to another test group

After creating the disposable account, an optional separate invocation can
target another authorized test group:

```powershell
.\Invoke-SuspiciousAccountAddition.ps1 -UserName "bad.user" -DomainGroup "Backup Operators"
```

Record each group changed and remove each added membership during cleanup.
Without `-CreateUser`, the account must already exist. Running the script with
no arguments on a fresh deployment does not create `bad.user`.

### Expected Output

```text
[*] Domain: mayor.mcweeinc.com
[*] Starting suspicious account addition simulation...
[*] Target User: bad.user
[*] Target Group: Domain Admins
...
[+] Group found: CN=Domain Admins,CN=Users,DC=mayor,DC=mcweeinc,DC=com
[*] Adding user 'bad.user' to group 'Domain Admins'...
[+] Successfully added 'bad.user' to 'Domain Admins'!
[*] This action may trigger security alerts in Microsoft Defender for Identity.
```

This illustrates a successful addition; account-creation messages are omitted.
Actual distinguished names depend on your domain and account location. If the
account is already a member, the script reports that condition without adding it
again; an error or an unchanged membership is not a new successful addition.

## Scenario Execution

1. Capture the identity, domain, baseline membership, and exercise start time.
2. Run the account-creation example only after verifying the name is disposable
   and absent.
3. Confirm the actual membership with
   `Get-ADGroupMember -Identity "Domain Admins"` and review script errors.
4. Correlate the actor, target account, selected group, and time range in the
   Defender portal and available directory audit data.
5. Compare any alerts with the candidate below. A successful membership change
   does not guarantee an MDI alert.
6. Remove only the scenario changes and verify the baseline is restored.

## Expected Alerts

The following is a candidate detection, not a promise that a single addition
will generate an alert. Availability, severity, and timing depend on sensor
health, tenant configuration, behavioral context, and observed activity.

| Alert Title | Alert Description | Alert Details |
| -- | -- | -- |
| Suspicious additions to sensitive groups | An account added the disposable scenario user to a sensitive group. | **Category:** Persistence<br/>**MITRE ATT&CK Techniques:** T1098: Account Manipulation; T1136.002: Create Account: Domain Account when account creation was performed<br/>**Service source:** Microsoft Defender for Identity<br/>**Detection status:** Not validated in this walkthrough |

## Why Does This Matter

1. **Privilege escalation** can turn an otherwise unprivileged account into a
   highly privileged identity through group membership.
2. **Persistence** can survive changes to an attacker's original access path.
3. **Actor attribution** distinguishes the administrator making the change
   from the account receiving permissions.
4. **Validation and cleanup** demonstrate both detection opportunities and the
   need to restore the original directory state.

## Best Practices

1. Use an authorized administrator only for the required changes and keep the
   disposable account separate from deployment and hydrated identities.
2. Record the baseline and every group modified; the script handles one group
   per invocation, not a complete rollback of all account changes.
3. Use a unique lab-only password and protect console output and transcripts.
4. Review audit records and actual group membership rather than relying only
   on console success messages or the presence of an alert.
5. Clean up promptly and verify that no scenario-created privileged membership
   or account remains.

### Investigating unexpected activity

If unrelated or unauthorized changes are discovered, investigate the actor and
audit history, review other sensitive memberships and persistence mechanisms,
and follow your incident-response process. Remove unauthorized permissions,
disable or delete confirmed malicious accounts, and reset potentially
compromised credentials as appropriate. Do not treat legitimate deployment or
hydrated accounts as disposable cleanup targets.

## Clean-Up

Run cleanup in the same verified domain context and with permission to manage
the affected group. Substitute your exact scenario username and group if you
changed them.

### Remove membership but keep the disposable account

```powershell
.\Invoke-SuspiciousAccountAddition.ps1 -UserName "bad.user" -DomainGroup "Domain Admins" -Cleanup
```

If you ran the optional second-group example, remove that membership too:

```powershell
.\Invoke-SuspiciousAccountAddition.ps1 -UserName "bad.user" -DomainGroup "Backup Operators" -Cleanup
```

### Remove membership and delete the disposable account

Only after confirming that the account belongs exclusively to this exercise:

```powershell
.\Invoke-SuspiciousAccountAddition.ps1 -UserName "bad.user" -DomainGroup "Domain Admins" -Cleanup -DeleteUser
```

Deletion is not restricted to accounts the script created: it can delete an
existing account supplied by name. If the selected group cannot be found,
cleanup exits before deleting the account, so check the outcome rather than
assuming deletion succeeded.

Verify the final group membership and account state:

```powershell
Get-ADGroupMember -Identity "Domain Admins" | Select-Object SamAccountName
Get-ADUser -Filter 'SamAccountName -eq "bad.user"'
```

If you retained the account, confirm its scenario-added memberships are removed;
if you deleted it, the filtered user query should return no object.
Clear the credential variables from this PowerShell session when finished:

```powershell
Remove-Variable -Name credential, accountParameters -ErrorAction SilentlyContinue
```

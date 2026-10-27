# LDAP Reconnaissance

> **Lab context:** Use `WinClient11` (`10.0.2.51`) as `mayor\jsmith`,
> querying `LabSubAd1` (`10.0.2.15`) in `mayor.mcweeinc.com`.
> Complete the [scenario setup](README.md#before-running-a-scenario) first;
> domain membership and MDI onboarding are not automatic.

## Overview

LDAP reconnaissance queries Active Directory to discover users, groups, computers,
service principal names (SPNs), and other directory objects. Attackers can use this
information to identify privileged accounts, services, and potential targets.

This scenario uses direct LDAP queries against the selected lab forest and
exports the results to CSV files. It does not modify directory objects, request
Kerberos service tickets, or perform password attacks.

## MITRE ATT&CK Mapping

| Tactic | Technique | ID |
| -- | -- | -- |
| Discovery | Account Discovery: Domain Account | T1087.002 |
| Discovery | Permission Groups Discovery: Domain Groups | T1069.002 |
| Discovery | Remote System Discovery | T1018 |
| Discovery | Domain Trust Discovery | T1482 |

## Attack Simulation

### Prerequisites

- Prepared, domain-joined `WinClient11` with Windows PowerShell and the
  `System.DirectoryServices.Protocols` .NET assembly; RSAT is not required by
  this script.
- AD DNS configured for the selected forest and network access to
  `LabSubAd1.mayor.mcweeinc.com` on TCP 389, subject to the controller's LDAP
  signing and authentication policies.
- A domain account permitted to read the queried objects. Start with
  `mayor\jsmith`; local or domain administrator privileges are not normally
  required for directory reads.
- A writable, dedicated output directory. Exported data includes account and
  infrastructure details and must remain inside the authorized lab.
- For MDI validation, a healthy sensor on the target controller and access to
  the appropriate Defender portal investigation or hunting features.
- For optional LDAPS, an LDAPS-configured controller and access to its TLS port,
  normally TCP 636. Deployment does not automatically configure this.

### Script: Invoke-LdapRecon.ps1

The [Invoke-LdapRecon.ps1](./Invoke-LdapRecon.ps1) script uses
`System.DirectoryServices.Protocols` to bind to a controller, perform paged
directory searches, and export the results.

#### Parameters

| Parameter | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `-OutputPath` | String | No | `$env:TEMP\LdapRecon` | Directory for CSV exports; cleanup deletes this entire directory. |
| `-DomainController` | String | No | `DC1` | Controller to query. Override with `LabSubAd1.mayor.mcweeinc.com` for the first lab forest. |
| `-Port` | Int | No | `389` | LDAP port. With `-UseSSL`, the script changes port `389` to `636`; other supplied ports are retained. |
| `-UseSSL` | Switch | No | Not set | Enables LDAPS. The current script accepts any server certificate; this is a lab-only option, not certificate-validated TLS. |
| `-Username` | String | No | `Administrator` | Explicit bind identity, used only when `-Password` is also supplied. Otherwise the script uses the signed-in account. |
| `-Password` | SecureString | No | Not set | Password for the explicit bind identity; use a credential prompt rather than a literal password. |
| `-DomainName` | String | No | `contoso.com` | Domain converted to an LDAP search base. Override with `mayor.mcweeinc.com`. |
| `-CleanUp` | Switch | No | Not set | Deletes `OutputPath` and returns without connecting to LDAP. |

None of the parameters is mandatory to PowerShell, but the generic `DC1`,
`Administrator`, and `contoso.com` defaults do not describe this deployment.
Specify the lab controller and domain; supply both credential parameters if
not using the signed-in domain account.

#### What the Script Does

1. Converts the supplied domain into a search base, such as
   `DC=mayor,DC=mcweeinc,DC=com`.
2. Connects to the selected LDAP endpoint using explicit credentials or the
   current Windows identity.
3. Queries directory objects using paged searches, including users, groups,
   computers, SPNs, privileged users, controllers, trusts, and Group Policy.
4. Writes CSV files for searches that return results and always exports a
   statistics file if execution reaches that stage.
5. Prints the target, object counts, and output location, then closes the
   connection.

## Setup

Download [Invoke-LdapRecon.ps1](./Invoke-LdapRecon.ps1) to the prepared
`WinClient11` and open Windows PowerShell in that directory.
Complete the [shared scenario setup](README.md#before-running-a-scenario)
before running queries.

For second-forest exercises, change the controller, domain, and account together
to `LabSubAd2.tech.mcweeinc.com`, `tech.mcweeinc.com`, and `tech\jsmith`.
The deployment creates independent forests, not a trust between them.

### Usage Examples

#### Use the signed-in lab account

Run as `mayor\jsmith`; this example uses the current Windows credentials:

```powershell
.\Invoke-LdapRecon.ps1 -DomainController "LabSubAd1.mayor.mcweeinc.com" -DomainName "mayor.mcweeinc.com"
```

#### Supply explicit lab credentials

Prompt for the hydrated user's password and pass it as a `SecureString`:

```powershell
$credential = Get-Credential -UserName "jsmith@mayor.mcweeinc.com" -Message "Enter the hydrated lab user's password"
$ldapParameters = @{
    DomainController = "LabSubAd1.mayor.mcweeinc.com"
    DomainName = "mayor.mcweeinc.com"
    Username = $credential.UserName
    Password = $credential.Password
}
.\Invoke-LdapRecon.ps1 @ldapParameters
```

#### Use a dedicated output directory

```powershell
$outputPath = Join-Path $env:TEMP "LdapRecon-Scenario"
.\Invoke-LdapRecon.ps1 -DomainController "LabSubAd1.mayor.mcweeinc.com" -DomainName "mayor.mcweeinc.com" -OutputPath $outputPath
```

### Expected Output

Illustrative output for the signed-in account example:

```text
[*] LDAP Reconnaissance Script
[*] Using System.DirectoryServices.Protocols for direct LDAP queries
...
[+] Using search base: DC=mayor,DC=mcweeinc,DC=com
[*] Target: LabSubAd1.mayor.mcweeinc.com:389
[*] SSL: False
[*] Using current user credentials
[+] Successfully connected to LDAP server
...
[+] Exported statistics to Statistics.csv
```

| File | Contents |
| -- | -- |
| `DomainInfo.csv` | Domain object details. |
| `OrganizationalUnits.csv` | Organizational units and selected attributes. |
| `Users.csv` | User attributes, memberships, and decoded account-control flags. |
| `Groups.csv` | Groups and memberships. |
| `Computers.csv` | Computer identities and operating-system attributes. |
| `ServicePrincipalNames.csv` | Objects with registered SPNs. |
| `PrivilegedUsers.csv` | User objects with `adminCount=1`; not a complete effective-privilege assessment. |
| `DomainControllers.csv` | Controller computer objects in the selected domain. |
| `DomainTrusts.csv` | Trust objects, if present. |
| `GroupPolicyObjects.csv` | Group Policy container metadata. |
| `AllObjects.csv` | High-level directory object inventory. |
| `Statistics.csv` | Target information and counts for the completed searches. |

Files and counts depend on permissions, directory contents, and query success.
For example, a new independent lab forest may have no trust objects and produce
no `DomainTrusts.csv`. LDAP search errors can be logged as warnings while later
searches continue; the completion banner alone does not prove every query
succeeded.

## Scenario Execution

1. On `WinClient11`, verify the account with `whoami` and confirm the selected
   controller resolves through AD DNS.
2. Run one of the examples above with the controller and domain for the same
   forest.
3. Review connection errors, search warnings, the generated CSV files, and
   `Statistics.csv` before interpreting results.
4. Investigate the source device, account, controller, and execution time in the
   Defender portal. Where available, inspect `IdentityQueryEvents` for related
   query telemetry.
5. Compare any alerts with the candidates below; no fixed alert count or arrival
   time is guaranteed.
6. Preserve only the evidence needed for the exercise, then follow cleanup.

## Expected Alerts

The following titles are examples of potentially related detections, not
guaranteed results from one script invocation. Alert availability and timing
depend on sensor health, tenant configuration, behavioral baselines, and the
activity observed. Directory SPN enumeration is not itself a Kerberoasting or
authentication attack; those alert categories require additional supporting
activity and should not be treated as proof this read-only scenario performed it.

| Alert Title | Alert Description | Alert Details |
| -- | -- | -- |
| Possible SPN enumeration via LDAP | One or more potential Service Principal Name (SPN) scanning activities via Lightweight Directory Access Protocol (LDAP) have been detected. This enumeration might indicate an attacker's reconnaissance within the organization and could be used in attacks such as Kerberoasting. | **Category:** Discovery<br/> **MITRE ATT&CK Techniques:** T1087: Account Discovery<br/>T1087.002: Domain Account<br/>**Service source:** Microsoft Defender for Identity<br/>**Detection source:** Defender XDR<br/>**Detection technology:**-<br/>**Detection status:** Unknown |
| Security principal reconnaissance (LDAP) | Actors on *machine* sent suspicious LDAP queries to *Domain Controller*, searching for 7 types of enumeration in forestdnszones.*domainname*, domaindnszones.*domainname* and *domainname* | **Category:** Discovery<br/> **MITRE ATT&CK Techniques:** T1087: Account Discovery, T1087.002: Domain Account, T1069: Permission Groups Discovery, T1069.002: Domain Groups, T1482: Domain Trust Discovery<br/>**Service source:** Microsoft Defender for Identity<br/>**Detection source:** Defender for Identity<br/>**Detection technology:**-<br/>**Detection status:** Unknown |
| Suspicious authentication attempt | A suspicious authentication attempt has been observed. This anomalous authentication request is suspected to have been specially crafted by an attacker. The attacker might be using stolen hash or clear text password for authentication, possibly leveraging pass-the-hash or over-pass-the-hash attack. Investigate immediately to protect the account and organization from security breach. | **Category:** Lateral movement<br/> **MITRE ATT&CK Techniques:** T1558.003: Kerberoasting<br/>**Service source:** Microsoft Defender for Identity<br/>**Detection source:** Defender XDR<br/>**Detection technology:**-<br/>**Detection status:** Unknown |
| Suspicious LDAP query | LDAP focused security principal reconnaissance is commonly used as the first phase of a Kerberoasting attack. | **Category:** Discovery<br/> **MITRE ATT&CK Techniques:** T1046: Network Service Discovery, T1087.002: Domain Account<br/>**Service source:** Microsoft Defender for Endpoint<br/>**Detection source:** Defender XDR<br/>**Detection technology:**-<br/>**Detection status:** Unknown |

## Why Does This Matter

1. **Account discovery** reveals identities an attacker might target.
2. **Group and privilege discovery** exposes potentially sensitive memberships
   and accounts for investigation.
3. **Service and computer discovery** maps internal systems and registered
   services without changing directory objects.
4. **Detection validation** helps distinguish collected LDAP telemetry from
   alerts that depend on additional behavioral context.

## Best Practices

1. Query only an authorized lab forest and use the least-privileged account
   needed for the exercise.
2. Verify controller sensor health and record the source account, device, and
   run time before evaluating detections.
3. Keep CSV exports inside the lab; they contain sensitive directory details.
4. Review warnings and missing exports rather than assuming a completed run
   means all queries succeeded.
5. Do not use this script's certificate-accepting LDAPS behavior as a production
   transport-security pattern.
6. Keep deployment administrators and hydrated accounts separate from disposable
   scenario accounts; this script does not create or require a new account.

## Clean-Up

After collecting the required evidence, remove the default output directory
using the same Windows account that ran the queries:

```powershell
.\Invoke-LdapRecon.ps1 -CleanUp
```

If you used the dedicated output example, supply that exact directory:

```powershell
.\Invoke-LdapRecon.ps1 -CleanUp -OutputPath (Join-Path $env:TEMP "LdapRecon-Scenario")
```

Cleanup recursively deletes the entire selected output directory, including
pre-existing files. Verify the path first and never select a shared or parent
directory. No LDAP credentials are required for cleanup, and no directory
accounts, group memberships, or controller configuration need to be reverted.

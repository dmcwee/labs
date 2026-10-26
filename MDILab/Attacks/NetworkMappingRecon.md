# Network Mapping Reconnaissance

> **Lab context:** Use `WinClient11` (`10.0.2.51`) as `mayor\jsmith`,
> querying `LabSubAd1` (`10.0.2.15`) in `mayor.mcweeinc.com`.
> Complete the [scenario setup](README.md#before-running-a-scenario) first;
> domain membership and MDI onboarding are not automatic.

## Overview

Network mapping reconnaissance uses DNS information to discover internal
hostnames and potential targets. MDI can detect suspicious zone-transfer
requests from non-DNS hosts or unusual DNS query activity.

This scenario covers two distinct activities: a manual AXFR request with
`nslookup`, and DNS record queries with the shared
[Invoke-DnsZoneTransfer.ps1](./Invoke-DnsZoneTransfer.ps1) script.
Despite its name and banner, the current script does not send AXFR requests;
it calls `Resolve-DnsName` for individual record types. See the
[DNS scenario](DnsZoneTransfer.md) for its companion walkthrough.

## MITRE ATT&CK Mapping

| Tactic | Technique | ID |
| -- | -- | -- |
| Discovery | Remote System Discovery | T1018 |
| Discovery | Network Service Discovery | T1046 |

## Attack Simulation

### Prerequisites

- Prepared, domain-joined `WinClient11`, using AD DNS for
  `mayor.mcweeinc.com` and the standard domain account `mayor\jsmith`.
- DNS connectivity to `LabSubAd1` (`10.0.2.15`): TCP 53 for AXFR, and UDP/TCP 53
  as required for ordinary DNS queries.
- Windows `nslookup` for the manual example, and Windows PowerShell with
  `Resolve-DnsName` for the scripted example.
- A healthy MDI sensor on the controller and appropriate Defender portal access
  if evaluating detections.
- A dedicated, writable output directory for scripted results. The manual
  `nslookup` example does not create an output directory.

Standard DNS queries do not normally require administrator rights. A refused
zone transfer is a valid outcome; do not enable unrestricted zone transfers or
weaken DNS controls just to obtain a result or alert.

### Script: Invoke-DnsZoneTransfer.ps1

Use [Invoke-DnsZoneTransfer.ps1](./Invoke-DnsZoneTransfer.ps1) for DNS record
enumeration, not for the manual zone-transfer request.

#### Parameters

| Parameter | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `-Domain` | String | No | Not set | Domain to query; supply `mayor.mcweeinc.com`. |
| `-NameServer` | String | No | NS lookup | Specific DNS server; otherwise the script discovers NS records for the supplied domain. |
| `-OutputPath` | String | No | `$env:TEMP\DnsZoneTransfer` | Results directory; cleanup recursively deletes this entire directory. |
| `-TimeoutSec` | Int | No | `15` | Displayed in the banner, but the current implementation does not apply it to DNS queries. |
| `-RecordTypes` | String[] | No | Script-defined record-type list | Types to query. The example below selects specific types; some entries in the default list may be unsupported or return no records. |
| `-CleanUp` | Switch | No | Not set | Deletes the selected output directory instead of running queries. |
| `-Force` | Switch | No | Not set | Skips the confirmation prompt, including in cleanup mode. |

#### What the Script Does

1. Displays its configuration and asks for confirmation unless `-Force` is set.
2. Uses the supplied DNS server or discovers name servers through an NS lookup.
3. Calls `Resolve-DnsName` for each selected record type against those servers.
4. Appends record-type headings and query results to a text file per server.
5. Reports successful queries and queries that fail or return no results.

## Setup

Complete the [shared scenario setup](README.md#before-running-a-scenario).
On `WinClient11`, verify the signed-in account with `whoami` and confirm AD DNS
resolves `LabSubAd1.mayor.mcweeinc.com` to the selected lab controller.

Download [Invoke-DnsZoneTransfer.ps1](./Invoke-DnsZoneTransfer.ps1) if using
the scripted option and open Windows PowerShell in its directory.
For second-forest exercises, change the server and domain together to
`LabSubAd2.tech.mcweeinc.com` and `tech.mcweeinc.com`, using that forest's
prepared client membership and account.

### Usage Examples

#### Manual zone-transfer request

Open Command Prompt and enter these commands interactively:

```cmd
nslookup
server LabSubAd1.mayor.mcweeinc.com
ls -d mayor.mcweeinc.com
exit
```

The `server` command changes the DNS server only for that `nslookup` session.
The `ls -d` command attempts AXFR; the server's policy determines whether it
returns records or refuses the request.

#### Scripted DNS record enumeration

From Windows PowerShell, query a bounded selection of record types and store
results in a dedicated scenario directory:

```powershell
$outputPath = Join-Path $env:TEMP "NetworkMappingRecon"
.\Invoke-DnsZoneTransfer.ps1 -Domain "mayor.mcweeinc.com" -NameServer "LabSubAd1.mayor.mcweeinc.com" -RecordTypes @("A", "AAAA", "NS", "SOA", "MX", "TXT", "SRV") -OutputPath $outputPath
```

Review the banner and confirm only the intended lab target. A small number of
ordinary queries may not qualify as suspicious activity. Any additional runs
should be part of a planned, bounded exercise, not an unbounded query loop.

### Expected Output

The manual request may return records, a refusal, or a connectivity error.
A refusal does not mean the request was never observed, and it does not by
itself prove MDI generated an alert.

Illustrative scripted output:

```text
[+] DNS Resolve from LabSubAd1.mayor.mcweeinc.com for A succeeded
[-] DNS Resolve from LabSubAd1.mayor.mcweeinc.com for AAAA failed or returned no results
...
```

The scripted example writes
`ResolveDnsName_LabSubAd1.mayor.mcweeinc.com.txt` beneath
`$env:TEMP\NetworkMappingRecon`. Results depend on DNS records and server
policy. A file containing only query headings or "No results" is not a
successful inventory; inspect the contents and console messages.

## Scenario Execution

1. Confirm the source account, controller, domain, DNS connectivity, and sensor
   health before starting.
2. Record the source device and execution time, then run the manual request,
   the scripted queries, or both as intended by the exercise.
3. Record whether AXFR was allowed or refused, separately from ordinary record
   query results.
4. Investigate the source device, target controller, account, and time range in
   the Defender portal.
5. Compare observed telemetry and any alerts with the candidate below. There
   is no guaranteed alert count or fixed arrival time.
6. Preserve the required lab evidence and remove scripted exports after use.

## Expected Alerts

This is a candidate detection, not a guaranteed result from either example.
Availability and timing depend on sensor coverage, tenant configuration,
behavioral baselines, and observed query activity.

| Alert Title | Alert Description | Alert Details |
| -- | -- | -- |
| Network mapping reconnaissance (DNS) | Suspicious DNS activity, such as a zone-transfer request from an unexpected source or unusual query activity, may indicate network discovery. | **Category:** Discovery<br/>**MITRE ATT&CK Techniques:** T1046: Network Service Discovery, T1018: Remote System Discovery<br/>**Service source:** Microsoft Defender for Identity<br/>**Detection status:** Not validated in this walkthrough |

## Why Does This Matter

1. **Infrastructure discovery** can expose internal hostnames and systems.
2. **Zone-transfer restrictions** limit unauthorized access to complete DNS
   zone contents.
3. **Behavioral context** helps distinguish routine DNS lookups from unusual
   reconnaissance.
4. **Detection validation** separates a successful query, collected telemetry,
   and an actual alert; these are different outcomes.

## Best Practices

1. Keep all requests inside the authorized lab and record the exercise window.
2. Preserve zone-transfer restrictions and use least-privileged source accounts.
3. Keep scripted queries bounded and avoid unnecessarily loading DNS servers.
4. Review refusals, missing records, and sensor health before interpreting an
   absent alert as a detection failure.
5. Treat exported DNS data as sensitive and retain only what the exercise needs.

## Clean-Up

Exit `nslookup` if its interactive session is still open. The manual example
does not alter DNS records or persistent client DNS settings.

For the scripted example, use the same Windows account and exact output path:

```powershell
.\Invoke-DnsZoneTransfer.ps1 -CleanUp -OutputPath (Join-Path $env:TEMP "NetworkMappingRecon")
```

The script displays its standard confirmation prompt even for cleanup unless
`-Force` is supplied. In cleanup mode it deletes the selected directory rather
than running DNS queries. Verify the path first: the entire directory and any
pre-existing contents are removed. If you used another output directory,
substitute that exact path, never a shared or parent directory.

No domain accounts, group memberships, or DNS server settings are modified by
these examples.

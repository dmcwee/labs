# DNS Zone Transfer & Record Enumeration

> **Lab context:** Use `WinClient11` (`10.0.2.51`) as `mayor\jsmith`,
> querying `LabSubAd1` (`10.0.2.15`) in `mayor.mcweeinc.com`.
> Complete the [scenario setup](README.md#before-running-a-scenario) first;
> domain membership and MDI onboarding are not automatic.

## Overview

DNS Zone Transfer is a reconnaissance technique used by attackers to obtain a complete copy of DNS records for a domain. By performing zone transfer requests (AXFR) or exhaustively querying DNS record types, attackers can map the network infrastructure, discover internal hostnames, identify servers, and locate potential targets for further exploitation.

Microsoft Defender for Identity (MDI) detects suspicious DNS activity including zone transfer attempts originating from non-DNS servers and excessive DNS query volumes, which are strong indicators of network reconnaissance.

## MITRE ATT&CK Mapping

| Tactic | Technique | ID |
| --- | --- | --- |
| Discovery | Network Service Discovery | T1046 |
| Discovery | Remote System Discovery | T1018 |
| Reconnaissance | Active Scanning: Vulnerability Scanning | T1595.002 |
| Reconnaissance | Gather Victim Network Information: DNS | T1590.002 |

## Attack Simulation

### Prerequisites

- Domain-joined Windows machine with PowerShell
- Network connectivity to the domain's DNS server(s)
- For Script Execution the `Resolve-DnsName` cmdlet (available in Windows 8.1+ / Server 2012 R2+) 
- Standard domain user account (DNS queries typically don't require elevated privileges)

## Setup

Use the [Invoke-DnsZoneTransfer.ps1](./Invoke-DnsZoneTransfer.ps1) script to perform DNS reconnaissance.

### Usage Examples

#### Basic DNS enumeration with auto-discovered name servers

```powershell
.\Invoke-DnsZoneTransfer.ps1 -Domain "mayor.mcweeinc.com"
```

Discovers NS records for mayor.mcweeinc.com and queries all DNS record types against each name server.

#### Target a specific name server

```powershell
.\Invoke-DnsZoneTransfer.ps1 -Domain "mayor.mcweeinc.com" -NameServer "LabSubAd1.mayor.mcweeinc.com"
```

#### Query specific record types only

```powershell
.\Invoke-DnsZoneTransfer.ps1 -Domain "mayor.mcweeinc.com" -RecordTypes @("A", "AAAA", "MX", "NS", "SOA", "TXT", "SRV")
```

#### Skip confirmation prompt

```powershell
.\Invoke-DnsZoneTransfer.ps1 -Domain "mayor.mcweeinc.com" -Force
```

#### Custom output directory

```powershell
.\Invoke-DnsZoneTransfer.ps1 -Domain "mayor.mcweeinc.com" -OutputPath "C:\Results\DnsEnum"
```

### Expected Output

```
===============================================
   DNS Zone Transfer & Record Enumeration Tool
===============================================
Domain: mayor.mcweeinc.com
Output Path: C:\Users\jsmith\AppData\Local\Temp\DnsZoneTransfer
Record Types: A, AAAA, NS, MX, SOA, TXT, SRV, CNAME, ...
Name Server: (auto-discover)
Timeout (sec): 15

This script will attempt to enumerate DNS records and perform a zone transfer if possible.
Output will be saved to the specified path.

Do you want to continue? (Y/N): Y
[*] Discovering NS records for mayor.mcweeinc.com
[+] DNS Resolve from LabSubAd1.mayor.mcweeinc.com for A succeeded
[+] DNS Resolve from LabSubAd1.mayor.mcweeinc.com for NS succeeded
[-] DNS Resolve from LabSubAd1.mayor.mcweeinc.com for AXFR failed or returned no results
[+] DNS Resolve from LabSubAd1.mayor.mcweeinc.com for MX succeeded
...
```

Results are saved to `$OutputPath\ResolveDnsName_<nameserver>.txt`.

###

## Scenario Execution

1. Using a command prompt run the Zone Transfer commaonds below. This should generate an error in the console, but will also generate an alert in XDR.
2. Run the `Invoke-DnsZoneTransfer.ps1` script against your domain to enumerate all DNS record types.
3. For maximum detection coverage, run the script multiple times to generate excessive DNS query volume
4. Wait 5–15 minutes for MDI to process the activity
5. Check the Microsoft Security Portal for generated alerts

### Zone Transfer

You can also trigger a zone transfer detection using `nslookup` from a command prompt:

```cmd
nslookup
server LabSubAd1.mayor.mcweeinc.com
ls -d mayor.mcweeinc.com
exit
```
### Script: Invoke-DnsZoneTransfer.ps1

The `Invoke-DnsZoneTransfer.ps1` script attempts to enumerate DNS records by querying all possible DNS record types against the domain's name servers. It can auto-discover name servers or target a specific one. However, the script does not always trigger the same detections as the manual commands performed via nslookup.

#### Parameters

| Parameter | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `-Domain` | String | No | Not set | The domain name to enumerate DNS records for |
| `-NameServer` | String | No | *(Auto-discover)* | Specific name server to query. If not provided, NS records are resolved automatically |
| `-OutputPath` | String | No | `$env:TEMP\DnsZoneTransfer` | Directory path where results are saved |
| `-TimeoutSec` | Int | No | `15` | Timeout in seconds for DNS queries |
| `-RecordTypes` | String[] | No | All standard DNS types | Array of DNS record types to query (A, AAAA, MX, CNAME, SOA, NS, TXT, SRV, PTR, etc.) |
| `-CleanUp` | Switch | No | Not set | Removes previous output files from the output path |
| `-Force` | Switch | No | Not set | Skips the confirmation prompt |

#### What the Script Does

1. Displays a banner with configuration details and prompts for confirmation (unless `-Force` is specified)
2. Auto-discovers name servers via NS record lookup if `-NameServer` is not provided
3. Iterates through all specified DNS record types and queries each against every discovered name server
4. Saves results to text files in the output directory, one file per name server
5. Reports success or failure for each record type query

## Expected Alerts

| Alert Title | Alert Description | Severity | Timeline |
| --- | --- | --- | --- |
| Network mapping reconnaissance (DNS) | Suspicious DNS activity detected, indicating potential network reconnaissance | Medium | 5–15 minutes |

| Alert Title | Alert Description | Alert Details |
| --- | --- | --- |
| Network mapping reconnaissance (DNS) | Suspicious DNS queries originating from non-DNS server or excessive DNS enumeration detected | **Category:** Discovery<br>**MITRE ATT&CK Techniques:** T1046: Network Service Discovery, T1018: Remote System Discovery<br>**Service source:** MDI<br>**Detection source:** Defender XDR<br>**Detection technology:** Behavioral analytics<br>**Detection status:** Unknown |

## Why Does This Matter

1. **Network mapping** — DNS enumeration reveals internal hostnames, IP addresses, and service locations that attackers use to plan further attacks
2. **Zone transfer risk** — A successful zone transfer (AXFR) provides attackers with a complete inventory of all DNS records in the domain
3. **Pre-attack reconnaissance** — DNS enumeration is typically the first step before lateral movement, service exploitation, or targeted attacks
4. **Low barrier to entry** — DNS queries require no special privileges, making this technique accessible to any user on the network
5. **High signal detection** — Legitimate users rarely query all DNS record types or attempt zone transfers, making this activity a reliable indicator of compromise

## Best Practices

1. Disable DNS zone transfers to unauthorized hosts (restrict AXFR to known secondary DNS servers only)
2. Monitor DNS query logs for unusual volume or record type patterns
3. Configure MDI sensors on all domain controllers running DNS
4. Implement DNS query rate limiting where feasible
5. Use DNS security extensions (DNSSEC) to protect against DNS manipulation
6. Segment DNS servers and restrict access from untrusted network segments

## Clean-Up

Remove the output files generated by the script:

```powershell
.\Invoke-DnsZoneTransfer.ps1 -CleanUp
```

Or manually remove the output directory:

```powershell
Remove-Item -Path "$env:TEMP\DnsZoneTransfer" -Recurse -Force
```

No accounts, groups, or system configurations are modified by this script.

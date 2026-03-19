# DNS Zone Transfer & Record Enumeration

## Overview

DNS Zone Transfer is a reconnaissance technique used by attackers to obtain a complete copy of DNS records for a domain. By performing zone transfer requests (AXFR) or exhaustively querying DNS record types, attackers can map the network infrastructure, discover internal hostnames, identify servers, and locate potential targets for further exploitation.

Microsoft Defender for Identity (MDI) detects suspicious DNS activity including zone transfer attempts originating from non-DNS servers and excessive DNS query volumes, which are strong indicators of network reconnaissance.

## MITRE ATT&CK Mapping

| Tactic | Technique | ID |
| -- | -- | -- |
| Discovery | Network Service Discovery | T1046 |
| Discovery | Remote System Discovery | T1018 |
| Reconnaissance | Active Scanning: Vulnerability Scanning | T1595.002 |
| Reconnaissance | Gather Victim Network Information: DNS | T1590.002 |

## Attack Simulation

### Prerequisites

- Domain-joined Windows machine with PowerShell
- Network connectivity to the domain's DNS server(s)
- The `Resolve-DnsName` cmdlet (available in Windows 8.1+ / Server 2012 R2+)
- Standard domain user account (DNS queries typically don't require elevated privileges)

### Script: Invoke-DnsZoneTransfer.ps1

The `Invoke-DnsZoneTransfer.ps1` script attempts to enumerate DNS records by querying all possible DNS record types against the domain's name servers. It can auto-discover name servers or target a specific one.

#### Parameters

| Parameter | Type | Default | Description |
| -- | -- | -- | -- |
| `-Domain` | String | - | The domain name to enumerate DNS records for |
| `-NameServer` | String | *(Auto-discover)* | Specific name server to query. If not provided, NS records are resolved automatically |
| `-OutputPath` | String | `$env:TEMP\DnsZoneTransfer` | Directory path where results are saved |
| `-TimeoutSec` | Int | `15` | Timeout in seconds for DNS queries |
| `-RecordTypes` | String[] | All standard DNS types | Array of DNS record types to query (A, AAAA, MX, CNAME, SOA, NS, TXT, SRV, PTR, etc.) |
| `-CleanUp` | Switch | - | Removes previous output files from the output path |
| `-Force` | Switch | - | Skips the confirmation prompt |

#### What the Script Does

1. Displays a banner with configuration details and prompts for confirmation (unless `-Force` is specified)
2. Auto-discovers name servers via NS record lookup if `-NameServer` is not provided
3. Iterates through all specified DNS record types and queries each against every discovered name server
4. Saves results to text files in the output directory, one file per name server
5. Reports success or failure for each record type query

## Setup

Use the [Invoke-DnsZoneTransfer.ps1](./Invoke-DnsZoneTransfer.ps1) script to perform DNS reconnaissance.

### Usage Examples

#### Basic DNS enumeration with auto-discovered name servers

```powershell
.\Invoke-DnsZoneTransfer.ps1 -Domain "contoso.com"
```

Discovers NS records for contoso.com and queries all DNS record types against each name server.

#### Target a specific name server

```powershell
.\Invoke-DnsZoneTransfer.ps1 -Domain "contoso.com" -NameServer "DC01.contoso.com"
```

#### Query specific record types only

```powershell
.\Invoke-DnsZoneTransfer.ps1 -Domain "contoso.com" -RecordTypes @("A", "AAAA", "MX", "NS", "SOA", "TXT", "SRV")
```

#### Skip confirmation prompt

```powershell
.\Invoke-DnsZoneTransfer.ps1 -Domain "contoso.com" -Force
```

#### Custom output directory

```powershell
.\Invoke-DnsZoneTransfer.ps1 -Domain "contoso.com" -OutputPath "C:\Results\DnsEnum"
```

### Expected Output

```
===============================================
   DNS Zone Transfer & Record Enumeration Tool
===============================================
Domain: contoso.com
Output Path: C:\Users\user\AppData\Local\Temp\DnsZoneTransfer
Record Types: A, AAAA, NS, MX, SOA, TXT, SRV, CNAME, ...
Name Server: (auto-discover)
Timeout (sec): 15

This script will attempt to enumerate DNS records and perform a zone transfer if possible.
Output will be saved to the specified path.

Do you want to continue? (Y/N): Y
[*] Discovering NS records for contoso.com
[+] DNS Resolve from DC01.contoso.com for A succeeded
[+] DNS Resolve from DC01.contoso.com for NS succeeded
[-] DNS Resolve from DC01.contoso.com for AXFR failed or returned no results
[+] DNS Resolve from DC01.contoso.com for MX succeeded
...
```

Results are saved to `$OutputPath\ResolveDnsName_<nameserver>.txt`.

### Manual Zone Transfer (Alternative)

You can also trigger a zone transfer detection using `nslookup` from a command prompt:

```bash
nslookup
server DC01.contoso.com
ls -d contoso.com
exit
```

## Scenario Execution

1. Run the script against your lab domain to enumerate all DNS record types
2. For maximum detection coverage, run the script multiple times to generate excessive DNS query volume
3. Wait 5–15 minutes for MDI to process the activity
4. Check the Microsoft Security Portal for generated alerts

## Expected Alerts

| Alert Title | Alert Description | Severity | Timeline |
| -- | -- | -- | -- |
| Network mapping reconnaissance (DNS) | Suspicious DNS activity detected, indicating potential network reconnaissance | Medium | 5–15 minutes |

| Alert Title | Alert Description | Alert Details |
| -- | -- | -- |
| Network mapping reconnaissance (DNS) | Suspicious DNS queries originating from non-DNS server or excessive DNS enumeration detected | **Category:** Discovery<br/>**MITRE ATT&CK Techniques:** T1046: Network Service Discovery, T1018: Remote System Discovery<br/>**Service source:** MDI<br/>**Detection source:** Defender XDR<br/>**Detection technology:** Behavioral analytics<br/>**Detection status:** Unknown |

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

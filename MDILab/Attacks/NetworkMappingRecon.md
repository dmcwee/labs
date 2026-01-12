# Network Mapping Reconnaissance

This reconnaissance is used by attackers to map your network structure and target interesting computers for later steps in their attack.

There are several query types in the DNS protocol. This Defender for Identity security alert detects suspicious requests, either requests using an AXFR (transfer) originating from non-DNS servers, or those using an excessive number of requests.

## Simulation

Open a Windows command prompt and run the following commands:

```bash
Nslookup
Server DC01.MSMDI.local
ls -d MSMDI.local
exit
```

### Excessive DNS Queries

The `Invoke-DnsZoneTransfer.ps1` script attempts to query all possible DNS record types. Running this script multiple times can also result in Alerts being generated.

## Detections

| Alert Title | Alert Description | Alert Details |
| -- | -- | -- |
| xxx| xxx | **Category:** xxx<br/>**MITRE ATT&CK Techniques:** xxx<br/>**Service source:** xxx<br/>**Detection source:** xxx<br/>**Detection technology:** xxx<br/>**Detection status:** xxx |
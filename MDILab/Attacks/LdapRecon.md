# LDAP Reconnaisance

Attackers will use LDAP reconnaisance techniquest to discover valid users accounts and other objects within active directory. This information helps adversaries identify additional account and computer targets to further identify their foothold in the environment.

This simulation also includes searching and enumerating SPN values in the domain.

## Simulation

Run the following commands in PowerShell on a test device.

> Download the [simulation script here](./Invoke-LdapRecon.ps1)

### Perform Reconnaisance

```powershell
.\Invoke-LdapRecon.ps1 -DomainController <dc_name_here> -Username <domain_account> -Password $(ConvertTo-SecureString -AsPlainText -force) -DomainName <domain_name>
```

This will generate a series of csv files in the $env:TEMP\LdapRecon folder that contain details of various object from the domain.

### Cleanup Reconnaisance

```powershell
Invoke-LdapRecon.ps1 -Cleanup
```

## Detection
| Alert Title | Alert Description | Alert Details |
| -- | -- | -- |
| Possible SPN enumeration via LDAP | One or more potential Service Principal Name (SPN) scanning activities via Lightweight Directory Access Protocol (LDAP) have been detected. This enumeration might indicate an attacker's reconnaissance within the organization and could be used in attacks such as Kerberoasting. | **Category:** Discovery<br/> **MITRE ATT&CK Techniques:** T1087: Account Discovery<br/>T1087.002: Domain Account<br/>**Service source:** Microsoft Defender for Identity<br/>**Detection source:** Defender XDR<br/>**Detection technology:**-<br/>**Detection status:** Unknown |
| Security principal reconnaissance (LDAP) | Actors on *machine* sent suspicious LDAP queries to *Domain Controller*, searching for 7 types of enumeration in forestdnszones.*domainname*, domaindnszones.*domainname* and *domainname* | **Category:** Discovery<br/> **MITRE ATT&CK Techniques:** T1087: Account Discovery, T1087.002: Domain Account, T1069: Permission Groups Discovery, T1069.002: Domain Groups, T1482: Domain Trust Discovery<br/>**Service source:** Microsoft Defender for Identity<br/>**Detection source:** Defender for Identity<br/>**Detection technology:**-<br/>**Detection status:** Unknown |
| Suspicious authentication attempt | A suspicious authentication attempt has been observed. This anomalous authentication request is suspected to have been specially crafted by an attacker. The attacker might be using stolen hash or clear text password for authentication, possibly leveraging pass-the-hash or over-pass-the-hash attack. Investigate immediately to protect the account and organization from security breach. | **Category:** Lateral movement<br/> **MITRE ATT&CK Techniques:** T1558.003: Kerberoasting<br/>**Service source:** Microsoft Defender for Identity<br/>**Detection source:** Defender XDR<br/>**Detection technology:**-<br/>**Detection status:** Unknown |
| Suspicious LDAP query | LDAP focused security principal reconnaissance is commonly used as the first phase of a Kerberoasting attack. | **Category:** Discovery<br/> **MITRE ATT&CK Techniques:** T1046: Network Service Discovery, T1087.002: Domain Account<br/>**Service source:** Microsoft Defender for Endpoint<br/>**Detection source:** Defender XDR<br/>**Detection technology:**-<br/>**Detection status:** Detected |
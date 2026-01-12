# Honeytoken Account Activity Detection

## Scenario Summary

This scenario triggers Honeytoken alerts which are unused decoy account(s) placed in an environment and monitored as an early detection indicator.

## Setup

Use the [New-HoneyTokenAccount.ps1](./New-HoneyTokenAccount.ps1) script to create the adm_backup account as well as an interesting looking group.

Create the adm_backup account, Remote IT Admin group, and add adm_backup to the Remote IT Admin group
```powershell
New-HoneyTokenAccount.ps1
```

Create account Admin2 in a specific OU, the Remote IT Admin group, and add Admin2 to the Remote IT Admin group
```powershell
New-HoneyTokenAccount.ps1 -Username Admin2 -OU "OU=TestAccounts"
```

### Tag the Honey Token Account in MDI
Reference: Entity tags in Microsoft Defender for Identity - Microsoft Defender for Identity | Microsoft Learn

1. Open the Security Portal
1. Go to System -> Settings
1. Select Identities
  1. Under Entity Tags select Honeytoken
    1. Click the + Tag usersSelect the adm_backup user, or the name chosen by the customer, for use as a Honeytoken account
    1. Click Add selection
  1. Confirm the selected account(s) now appear in the Honeytoken list


## Scenario Execution
Use the following two scenarios to trigger Honey Token account detections.

### Authentication

From a testing machine open a command prompt and run the following command:
```bash
runas /user:CONTOSO\adm_backup cmd 
```

  > Replace CONTOSO\adm_backup with the name of the honey token account. 

When prompted provide either the correct or an incorrect password, either scenario should generate a detection result.

> Expected: “Honeytoken user authentication activity” alert; records in IdentityLogonEvents. Honeytoken activity IdentityLogonEvents table in the advanced hunting schema - Microsoft Defender XDR | Microsoft Learn

### LDAP Query

From the testing machine open a command prompt and run the following command:  
```bash
net user adm_backup /domain 
```

  > Replace adm_backup with the name of the honey token account.

> Expected: “Honeytoken user was queried via LDAP”; records in IdentityQueryEvents (ActionType LDAP query). Data tables in the Microsoft Defender XDR advanced hunting schema - Microsoft Defender XDR | Microsoft Learn

## Clean-Up

The `New-HoneyTokenAccount.ps1` script includes a clean up option to remove the testing honey token.

```powershell
New-HoneyTokenAccount.ps1 -cleanup
```

Create account Admin2 in a specific OU, the Remote IT Admin group, and add Admin2 to the Remote IT Admin group
```powershell
New-HoneyTokenAccount.ps1 -cleanup -Username Admin2
```

## Detections

| Alert Title | Alert Description | Alert Details |
| -- | -- | -- |
| Honeytoken authentication activity| *honey token account* performed *x* suspicious activities. | **Category:** Discovery<br/>**MITRE ATT&CK Techniques:** T1087: Account Discovery, T1087.002: Domain Account<br/>**Service source:** MDI<br/>**Detection source:** Unknownbr/>**Detection technology:** -<br/>**Detection status:** MDI |
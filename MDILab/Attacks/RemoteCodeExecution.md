# Remote Code Execution via PowerShell Remoting

## Overview

This attack simulation demonstrates a lateral movement technique where an attacker uses PowerShell Remoting (`Invoke-Command`) to execute code on a remote machine. The script connects to a target computer and writes an entry into the Windows Application Event Log, simulating a remote code execution scenario.

PowerShell Remoting is a legitimate administrative feature, but it is frequently abused by attackers for lateral movement after gaining initial access. Microsoft Defender for Identity (MDI) and Microsoft Defender for Endpoint (MDE) can detect suspicious remote execution patterns targeting monitored systems.

## MITRE ATT&CK Mapping

| Tactic | Technique | ID |
| -- | -- | -- |
| Lateral Movement | Remote Services: Windows Remote Management | T1021.006 |
| Execution | Command and Scripting Interpreter: PowerShell | T1059.001 |
| Lateral Movement | Remote Services | T1021 |

## Attack Simulation

### Prerequisites

- Domain-joined Windows machine with PowerShell
- PowerShell Remoting enabled on the target machine (`Enable-PSRemoting`)
- Network connectivity to the target machine (TCP port 5985 for HTTP or 5986 for HTTPS)
- Domain credentials with administrative access on the target machine
- Windows Remote Management (WinRM) service running on both source and target

### Script: Invoke-RemoteCodeExecution.ps1

The `Invoke-RemoteCodeExecution.ps1` script connects to a remote machine via PowerShell Remoting and writes a warning entry into the Windows Application Event Log, proving that code execution was achieved.

#### Parameters

| Parameter | Type | Default | Description |
| -- | -- | -- | -- |
| `-ComputerName` | String | *(Required)* | The name of the remote computer to connect to |
| `-Credential` | PSCredential | *(Current user)* | Optional credentials to use for the remote connection |

#### What the Script Does

1. Connects to the specified remote machine using `Invoke-Command`
2. Creates an event source named `RemoteCodeExecution` in the Application log (if it doesn't already exist)
3. Writes a warning event (Event ID 2026) with a message indicating the source machine
4. Returns the execution results to the caller

## Setup

Use the [Invoke-RemoteCodeExecution.ps1](./Invoke-RemoteCodeExecution.ps1) script to simulate the remote code execution.

Ensure PowerShell Remoting is enabled on the target machine:

```powershell
# Run on the target machine (requires admin)
Enable-PSRemoting -Force
```

### Usage Examples

#### Basic remote execution using current credentials

```powershell
.\Invoke-RemoteCodeExecution.ps1 -ComputerName "DC01"
```

Connects to DC01 using the current user's credentials and writes an event log entry.

#### Remote execution with explicit credentials

```powershell
.\Invoke-RemoteCodeExecution.ps1 -ComputerName "DC01" -Credential (Get-Credential)
```

Prompts for credentials, then connects and executes on DC01.

#### Remote execution with stored credentials

```powershell
$cred = Get-Credential -UserName "CONTOSO\admin" -Message "Enter admin credentials"
.\Invoke-RemoteCodeExecution.ps1 -ComputerName "SERVER01" -Credential $cred
```

### Expected Output

```
Attempting to connect to remote machine: DC01
Source machine: WORKSTATION01

Remote Execution Results:
Created event source: RemoteCodeExecution
Event log entry created successfully
Message: Remote code was executed on this machine from a connection on WORKSTATION01

Remote code execution simulation completed successfully!
```

## Scenario Execution

1. Identify a target machine (ideally a domain controller or server monitored by MDI)
2. Run the script with the target's computer name
3. Verify the event log entry was created on the target machine:
   ```powershell
   Get-EventLog -LogName Application -Source "RemoteCodeExecution" -Newest 1
   ```
4. Wait 5–15 minutes for MDI/MDE to process the activity
5. Check the Microsoft Security Portal for generated alerts

## Expected Alerts

| Alert Title | Alert Description | Severity | Timeline |
| -- | -- | -- | -- |
| Suspicious remote activity | Remote code execution detected from untrusted source | Medium | 5–15 minutes |
| Remote code execution attempt | Remote execution via PowerShell Remoting detected | Medium | 5–15 minutes |

| Alert Title | Alert Description | Alert Details |
| -- | -- | -- |
| Remote code execution attempt | Remote code was executed on *target machine* from *source machine* | **Category:** Lateral Movement<br/>**MITRE ATT&CK Techniques:** T1021.006: Windows Remote Management, T1059.001: PowerShell<br/>**Service source:** MDI / MDE<br/>**Detection source:** Defender XDR<br/>**Detection technology:** Behavioral analytics<br/>**Detection status:** Unknown |

## Why Does This Matter

1. **Lateral movement indicator** — PowerShell Remoting is a primary tool attackers use to move between machines after initial compromise
2. **Domain controller targeting** — Executing code on domain controllers can lead to full domain compromise
3. **Legitimate tool abuse** — WinRM/PSRemoting is a built-in Windows feature, making it harder to block outright
4. **Credential reuse** — This technique often relies on stolen or compromised credentials
5. **Forensic evidence** — The event log entry demonstrates that code ran on the remote machine, similar to how attackers deploy payloads

## Best Practices

1. Restrict PowerShell Remoting to authorized administrative workstations using GPO
2. Implement Just Enough Administration (JEA) to limit what remote sessions can do
3. Enable PowerShell Script Block Logging and Module Logging on all systems
4. Monitor WinRM connections in network traffic for unusual source/destination patterns
5. Use Windows Event Forwarding (WEF) to centralize PowerShell and WinRM logs
6. Restrict WinRM access using Windows Firewall rules and GPO settings
7. Require multi-factor authentication for remote administrative sessions where possible

## Clean-Up

Remove the event source created by the script on the target machine:

```powershell
Invoke-Command -ComputerName "DC01" -ScriptBlock {
    Remove-EventLog -Source "RemoteCodeExecution" -ErrorAction SilentlyContinue
}
```

No user accounts or group memberships are modified by this script.

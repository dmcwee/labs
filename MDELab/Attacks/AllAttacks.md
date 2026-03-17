# All Attack Simulations

## Overview

This is the master orchestration script that runs all individual MDE attack simulations in sequence. It provides an interactive menu for selecting which simulations to execute, displays severity-coded warnings, and produces a summary report of all test results. Use this script to perform a comprehensive security validation of your Microsoft Defender for Endpoint deployment in a single run.

## MITRE ATT&CK Mapping

This script orchestrates simulations that span multiple MITRE ATT&CK tactics and techniques:

| Tactic | Technique ID | Technique Name | Simulation |
| --- | --- | --- | --- |
| Discovery | T1087 | Account Discovery | AccountDiscovery |
| Persistence | T1136 | Create Account | AccountPersistence |
| Credential Access | T1003 | OS Credential Dumping | CredentialDumping |
| Defense Evasion | T1562.001 | Impair Defenses: Disable or Modify Tools | DefenderTampering |
| Impact | T1490 | Inhibit System Recovery | DeleteShadowCopy |
| Defense Evasion | T1070.001 | Indicator Removal: Clear Windows Event Logs | EventLog |
| Credential Access | T1552.001 | Unsecured Credentials: Credentials In Files | PasswordDetection |
| Execution | T1569.002 | System Services: Service Execution | ServiceExecution |
| Persistence | T1543.003 | Create or Modify System Process: Windows Service | ServiceWithEmbeddedExe |
| Privilege Escalation | T1548.002 | Abuse Elevation Control Mechanism: Bypass UAC | UACBypass |

## Expected Alerts

Running all simulations will generate multiple alerts across all severity levels in the Microsoft Defender for Endpoint portal. Refer to each individual simulation's documentation for specific alert details:

- [AccountDiscovery.md](AccountDiscovery.md)
- [AccountPersistence.md](AccountPersistence.md)
- [CredentialDumping.md](CredentialDumping.md)
- [DefenderTampering.md](DefenderTampering.md)
- [DeleteShadowCopy.md](DeleteShadowCopy.md)
- [EventLog.md](EventLog.md)
- [PasswordDetection.md](PasswordDetection.md)
- [ServiceExecution.md](ServiceExecution.md)
- [ServiceWithEmbeddedExe.md](ServiceWithEmbeddedExe.md)
- [UACBypass.md](UACBypass.md)

## Attack Simulation

### Prerequisites

- Windows 10/11 or Windows Server test environment
- PowerShell running as **Administrator**
- Microsoft Defender for Endpoint onboarded device
- All individual simulation scripts present in the same directory
- Dedicated test/lab environment (do **not** run on production systems)

### Script: Invoke-AllAttackSimulations.ps1

#### Parameters

| Parameter | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `ExcludeTests` | String[] | No | `@()` | Array of test names to exclude from execution. Valid values: `AccountDiscovery`, `AccountPersistence`, `CredentialDumping`, `DefenderTampering`, `DeleteShadowCopy`, `EventLog`, `PasswordDetection`, `ServiceExecution`, `ServiceWithEmbeddedExe`, `UACBypass` |
| `Force` | Switch | No | — | Pass the `-Force` parameter to individual scripts to skip their confirmation prompts (master confirmation is still required) |
| `ListTests` | Switch | No | — | Display the list of available test names and exit without executing |

#### What the Script Does

1. **Displays available simulations** — Lists all attack simulations with their severity ratings (Low, Medium, High, Critical) color-coded for visibility.
2. **Shows security warnings** — Presents detailed warnings about the impact of running attack simulations, including potential device isolation and alert generation.
3. **Requires explicit confirmation** — The user must type `I UNDERSTAND THE RISKS` to proceed with execution.
4. **Executes simulations sequentially** — Runs each selected simulation script in alphabetical order, passing the `-Force` flag if specified.
5. **Tracks results** — Records success/failure status and duration for each simulation.
6. **Produces a summary report** — Displays a final report with pass/fail counts, individual test results, and total execution duration.

## Setup

### Usage Examples

```powershell
# List all available simulations
.\Invoke-AllAttackSimulations.ps1 -ListTests

# Run all simulations interactively
.\Invoke-AllAttackSimulations.ps1

# Run all simulations with Force (skip individual script prompts)
.\Invoke-AllAttackSimulations.ps1 -Force

# Run all simulations except Credential Dumping and Defender Tampering
.\Invoke-AllAttackSimulations.ps1 -ExcludeTests "CredentialDumping","DefenderTampering"

# Run only low-risk simulations
.\Invoke-AllAttackSimulations.ps1 -ExcludeTests "CredentialDumping","DefenderTampering","DeleteShadowCopy" -Force
```

### Expected Output

```
=================================================================
                   *** CRITICAL WARNING ***
         Microsoft Defender for Endpoint Attack Simulator
=================================================================

The following attack simulations will be executed:
---------------------------------------------------
  [Low] AccountDiscovery
      Enumerate local and domain users and groups
  [High] AccountPersistence
      Create persistence mechanisms via registry/scheduler
  [Critical] CredentialDumping
      Dump LSASS memory and extract credentials
  ...

Type 'I UNDERSTAND THE RISKS' to proceed with execution.

[CONFIRMED] Starting attack simulation suite...

=================================================================
                  Execution Progress
=================================================================

[1/10] Executing: AccountDiscovery
    Script: Invoke-AccountDiscoverySimulation.ps1
    Severity: Low
    ...

=================================================================
                  Execution Summary
=================================================================

Total Tests Executed: 10
  Successful: 10
  Failed: 0
Total Duration: 45.23 seconds
```

## Scenario Execution

1. Ensure all individual simulation scripts are present in the same directory.
2. Open an elevated PowerShell prompt on the test device.
3. Optionally run `.\Invoke-AllAttackSimulations.ps1 -ListTests` to review available simulations.
4. Run `.\Invoke-AllAttackSimulations.ps1 -Force` (or without `-Force` for individual script confirmations).
5. Type `I UNDERSTAND THE RISKS` at the confirmation prompt.
6. Wait for all simulations to complete. The script displays progress for each test.
7. Review the execution summary for any failures.
8. Monitor the Microsoft Defender for Endpoint portal for alerts generated by each simulation.
9. Run cleanup for individual simulations as needed (see each simulation's documentation).

## Why Does This Matter

Running a comprehensive suite of attack simulations is essential for:

- **Validating detection coverage** — Ensures that your MDE deployment detects attacks across multiple MITRE ATT&CK tactics and techniques.
- **Testing alert pipeline** — Verifies that alerts are generated, properly categorized, and routed to the security team.
- **Benchmarking response capabilities** — Provides a baseline for measuring how quickly your security operations center (SOC) can detect and respond to simulated threats.
- **Compliance validation** — Demonstrates that endpoint protection controls are functioning as expected for audit and compliance requirements.

## Best Practices

- Always run simulations in a dedicated test/lab environment, never on production systems
- Notify your security team before running simulations to avoid unnecessary incident response
- Run `.\Invoke-AllAttackSimulations.ps1 -ListTests` first to understand what will be executed
- Use `-ExcludeTests` to skip simulations that are not relevant to your testing objectives
- Review individual simulation documentation before running for the first time
- Document the results and compare against expected alerts for each simulation
- Run cleanup procedures for each individual simulation after testing is complete

## Clean-Up

This script does not have a single cleanup command. Each individual simulation must be cleaned up separately:

```powershell
.\Invoke-AccountDiscoverySimulation.ps1 -CleanUp
.\Invoke-AccountPersistenceSimulation.ps1 -CleanUp
.\Invoke-CredentialDumpingSimulation.ps1 -CleanUp
.\Invoke-DefenderTamperingSimulation.ps1 -CleanUp
.\Invoke-DeleteShadowCopySimulation.ps1 -CleanUp
.\Invoke-EventLogSimulation.ps1 -CleanUp
.\Invoke-PasswordDetectionSimulation.ps1 -CleanUp
.\Invoke-ServiceExecutionSimulation.ps1 -CleanUp
.\Invoke-ServiceWithEmbeddedExeSimulation.ps1 -Cleanup
.\Invoke-UACBypassSimulation.ps1 -CleanUp
```

## References

- [Microsoft Defender for Endpoint Documentation](https://docs.microsoft.com/en-us/microsoft-365/security/defender-endpoint/)
- [MITRE ATT&CK Framework](https://attack.mitre.org/)
- [Microsoft Security Best Practices](https://docs.microsoft.com/en-us/security/compass/compass)

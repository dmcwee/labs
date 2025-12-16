<#
.SYNOPSIS
    Master script to run all MDE attack simulations with user selection capabilities.

.DESCRIPTION
    This script provides an interactive menu to select which attack simulations to run.
    Users can exclude specific tests and receive warnings about the actions that will be performed.
    All scripts will be executed with their default parameters unless specified otherwise.

.PARAMETER ExcludeTests
    Array of test names to exclude from execution. Use tab completion or -ListTests to see available tests.

.PARAMETER Force
    Skip individual script confirmation prompts (master confirmation still required).

.PARAMETER ListTests
    Display available test names and exit.

.EXAMPLE
    .\Invoke-AllAttackSimulations.ps1
    Run all tests with interactive selection.

.EXAMPLE
    .\Invoke-AllAttackSimulations.ps1 -ExcludeTests "CredentialDumping","DefenderTampering"
    Run all tests except Credential Dumping and Defender Tampering.

.EXAMPLE
    .\Invoke-AllAttackSimulations.ps1 -ListTests
    Display list of available tests.

.EXAMPLE
    .\Invoke-AllAttackSimulations.ps1 -Force
    Run with Force parameter passed to individual scripts (skip their prompts).
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [ValidateSet(
        "AccountDiscovery",
        "AccountPersistence",
        "CredentialDumping",
        "DefenderTampering",
        "DeleteShadowCopy",
        "EventLog",
        "PasswordDetection",
        "ServiceExecution",
        "ServiceWithEmbeddedExe",
        "UACBypass"
    )]
    [string[]]$ExcludeTests = @(),

    [Parameter(Mandatory = $false)]
    [switch]$Force,

    [Parameter(Mandatory = $false)]
    [switch]$ListTests
)

# Define all available attack simulations
$availableTests = @{
    "AccountDiscovery" = @{
        Script = "Invoke-AccountDiscoverySimulation.ps1"
        Description = "Enumerate local and domain users and groups"
        Severity = "Low"
        Parameters = @{}
    }
    "AccountPersistence" = @{
        Script = "Invoke-AccountPersistenceSimulation.ps1"
        Description = "Create persistence mechanisms via registry/scheduler"
        Severity = "High"
        Parameters = @{}
    }
    "CredentialDumping" = @{
        Script = "Invoke-CredentialDumpingSimulation.ps1"
        Description = "Dump LSASS memory and extract credentials"
        Severity = "Critical"
        Parameters = @{}
    }
    "DefenderTampering" = @{
        Script = "Invoke-DefenderTamperingSimulation.ps1"
        Description = "Disable Defender real-time protection and add exclusions"
        Severity = "Critical"
        Parameters = @{}
    }
    "DeleteShadowCopy" = @{
        Script = "Invoke-DeleteShadowCopySimulation.ps1"
        Description = "Delete shadow copies (ransomware behavior)"
        Severity = "Critical"
        Parameters = @{}
    }
    "EventLog" = @{
        Script = "Invoke-EventLogSimulation.ps1"
        Description = "Clear system event logs to cover tracks"
        Severity = "High"
        Parameters = @{}
    }
    "PasswordDetection" = @{
        Script = "Invoke-PasswordDetectionSimulation.ps1"
        Description = "Search for passwords in registry and files"
        Severity = "Medium"
        Parameters = @{}
    }
    "ServiceExecution" = @{
        Script = "Invoke-ServiceExecutionSimulation.ps1"
        Description = "Create and install malicious Windows service"
        Severity = "High"
        Parameters = @{}
    }
    "ServiceWithEmbeddedExe" = @{
        Script = "Invoke-ServiceWithEmbeddedExeSimulation.ps1"
        Description = "Compile C# service executable and install as service"
        Severity = "High"
        Parameters = @{}
    }
    "UACBypass" = @{
        Script = "Invoke-UACBypassSimulation.ps1"
        Description = "Bypass User Account Control using registry manipulation"
        Severity = "High"
        Parameters = @{}
    }
}

# Get script directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Function to display available tests
function Show-AvailableTests {
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "    Available Attack Simulations" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    
    $availableTests.GetEnumerator() | Sort-Object Name | ForEach-Object {
        $severity = $_.Value.Severity
        $color = switch ($severity) {
            "Low"      { "Green" }
            "Medium"   { "Yellow" }
            "High"     { "DarkYellow" }
            "Critical" { "Red" }
            default    { "White" }
        }
        
        Write-Host "`n  $($_.Key)" -ForegroundColor White -NoNewline
        Write-Host " [$severity]" -ForegroundColor $color
        Write-Host "    $($_.Value.Description)" -ForegroundColor Gray
    }
    
    Write-Host "`n========================================`n" -ForegroundColor Cyan
}

# If ListTests is specified, show tests and exit
if ($ListTests) {
    Show-AvailableTests
    Write-Host "To exclude tests, use: -ExcludeTests `"TestName1`",`"TestName2`"`n" -ForegroundColor Cyan
    exit
}

# Determine which tests to run
$testsToRun = $availableTests.Keys | Where-Object { $_ -notin $ExcludeTests } | Sort-Object

# Display header
Clear-Host
Write-Host "`n" -NoNewline
Write-Host "=================================================================" -ForegroundColor Red
Write-Host "                   *** CRITICAL WARNING ***" -ForegroundColor Red
Write-Host "         Microsoft Defender for Endpoint Attack Simulator" -ForegroundColor Yellow
Write-Host "=================================================================" -ForegroundColor Red

# Display tests that will be executed
Write-Host "`nThe following attack simulations will be executed:" -ForegroundColor White
Write-Host "---------------------------------------------------" -ForegroundColor Gray

$testsToRun | ForEach-Object {
    $test = $availableTests[$_]
    $severity = $test.Severity
    $color = switch ($severity) {
        "Low"      { "Green" }
        "Medium"   { "Yellow" }
        "High"     { "DarkYellow" }
        "Critical" { "Red" }
        default    { "White" }
    }
    
    Write-Host "  [$severity]" -ForegroundColor $color -NoNewline
    Write-Host " $_" -ForegroundColor White
    Write-Host "      $($test.Description)" -ForegroundColor Gray
}

# Display excluded tests if any
if ($ExcludeTests.Count -gt 0) {
    Write-Host "`nExcluded tests:" -ForegroundColor Yellow
    $ExcludeTests | ForEach-Object {
        Write-Host "  - $_" -ForegroundColor Gray
    }
}

# Display warnings
Write-Host "`n=================================================================" -ForegroundColor Red
Write-Host "                      SECURITY WARNINGS" -ForegroundColor Red
Write-Host "=================================================================" -ForegroundColor Red
Write-Host "`nThese simulations may cause Microsoft Defender for Endpoint to:" -ForegroundColor Yellow
Write-Host "  • Flag this device as COMPROMISED" -ForegroundColor Magenta
Write-Host "  • Generate HIGH-SEVERITY security alerts" -ForegroundColor Magenta
Write-Host "  • Potentially ISOLATE this device from the network" -ForegroundColor Magenta
Write-Host "  • Trigger incident response procedures" -ForegroundColor Magenta
Write-Host "`nYour account and device will be subject to investigation." -ForegroundColor Yellow
Write-Host "`nDO NOT run these simulations on:" -ForegroundColor Red
Write-Host "  • Production systems" -ForegroundColor Red
Write-Host "  • Systems with critical data" -ForegroundColor Red
Write-Host "  • Systems you don't have authorization to test" -ForegroundColor Red
Write-Host "`nONLY run these simulations on:" -ForegroundColor Green
Write-Host "  • Dedicated test/lab environments" -ForegroundColor Green
Write-Host "  • Systems you have explicit permission to test" -ForegroundColor Green
Write-Host "  • Environments with proper security team notification" -ForegroundColor Green
Write-Host "`n=================================================================" -ForegroundColor Red

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "`nWARNING: Not running as Administrator!" -ForegroundColor Red
    Write-Host "Some tests may fail or require elevation." -ForegroundColor Yellow
}

# Show current user
Write-Host "`nCurrent User: $env:USERDOMAIN\$env:USERNAME" -ForegroundColor Cyan
Write-Host "Computer Name: $env:COMPUTERNAME" -ForegroundColor Cyan
Write-Host "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan

Write-Host "`n=================================================================" -ForegroundColor Red
Write-Host "`nType 'I UNDERSTAND THE RISKS' to proceed with execution." -ForegroundColor Yellow
Write-Host "Type anything else to cancel." -ForegroundColor Yellow
Write-Host "`n=================================================================" -ForegroundColor Red

$confirmation = Read-Host "`nYour response"

if ($confirmation -ne "I UNDERSTAND THE RISKS") {
    Write-Host "`n[CANCELLED] Attack simulation suite cancelled by user." -ForegroundColor Green
    Write-Host "No tests were executed.`n" -ForegroundColor Green
    exit
}

# Confirm execution
Write-Host "`n[CONFIRMED] Starting attack simulation suite..." -ForegroundColor Red
Start-Sleep -Seconds 2

# Execute tests
$results = @()
$totalTests = $testsToRun.Count
$currentTest = 0

Write-Host "`n=================================================================" -ForegroundColor Cyan
Write-Host "                  Execution Progress" -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

foreach ($testName in $testsToRun) {
    $currentTest++
    $test = $availableTests[$testName]
    $scriptPath = Join-Path $scriptDir $test.Script
    
    Write-Host "`n[$currentTest/$totalTests] Executing: $testName" -ForegroundColor White
    Write-Host "    Script: $($test.Script)" -ForegroundColor Gray
    Write-Host "    Severity: $($test.Severity)" -ForegroundColor $(
        switch ($test.Severity) {
            "Low"      { "Green" }
            "Medium"   { "Yellow" }
            "High"     { "DarkYellow" }
            "Critical" { "Red" }
            default    { "White" }
        }
    )
    Write-Host "    Time: $(Get-Date -Format 'HH:mm:ss')" -ForegroundColor Gray
    Write-Host ("-" * 65) -ForegroundColor Gray
    
    try {
        # Build parameter list
        $params = @{}
        if ($Force) {
            $params['Force'] = $true
        }
        
        # Add any additional parameters from the test definition
        foreach ($param in $test.Parameters.Keys) {
            $params[$param] = $test.Parameters[$param]
        }
        
        # Execute the script
        $startTime = Get-Date
        & $scriptPath @params
        $endTime = Get-Date
        $duration = $endTime - $startTime
        
        $results += [PSCustomObject]@{
            TestName = $testName
            Status = "Success"
            Duration = $duration.TotalSeconds
            Timestamp = $startTime
            Error = $null
        }
        
        Write-Host "`n    Status: SUCCESS" -ForegroundColor Green
        Write-Host "    Duration: $($duration.TotalSeconds) seconds" -ForegroundColor Gray
        
    } catch {
        $results += [PSCustomObject]@{
            TestName = $testName
            Status = "Failed"
            Duration = 0
            Timestamp = Get-Date
            Error = $_.Exception.Message
        }
        
        Write-Host "`n    Status: FAILED" -ForegroundColor Red
        Write-Host "    Error: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    Write-Host ("-" * 65) -ForegroundColor Gray
}

# Display summary
Write-Host "`n=================================================================" -ForegroundColor Cyan
Write-Host "                  Execution Summary" -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

$successCount = ($results | Where-Object { $_.Status -eq "Success" }).Count
$failureCount = ($results | Where-Object { $_.Status -eq "Failed" }).Count
$totalDuration = ($results | Measure-Object -Property Duration -Sum).Sum

Write-Host "`nTotal Tests Executed: $totalTests" -ForegroundColor White
Write-Host "  Successful: $successCount" -ForegroundColor Green
Write-Host "  Failed: $failureCount" -ForegroundColor $(if ($failureCount -gt 0) { "Red" } else { "Green" })
Write-Host "Total Duration: $([math]::Round($totalDuration, 2)) seconds" -ForegroundColor White

Write-Host "`nDetailed Results:" -ForegroundColor White
Write-Host ("-" * 65) -ForegroundColor Gray
$results | ForEach-Object {
    $statusColor = if ($_.Status -eq "Success") { "Green" } else { "Red" }
    Write-Host "  $($_.TestName)" -NoNewline
    Write-Host " - $($_.Status)" -ForegroundColor $statusColor
    
    if ($_.Error) {
        Write-Host "    Error: $($_.Error)" -ForegroundColor Red
    }
}

Write-Host "`n=================================================================" -ForegroundColor Cyan
Write-Host "`nExecution completed at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
Write-Host "`nREMINDER: Check Microsoft Defender for Endpoint portal for alerts." -ForegroundColor Yellow
Write-Host "These simulations should have generated detectable security events.`n" -ForegroundColor Yellow
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host ""

# Return results object
return $results

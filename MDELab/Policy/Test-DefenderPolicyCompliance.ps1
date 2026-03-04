<#
.SYNOPSIS
    Tests local Microsoft Defender for Endpoint settings against recommended policy values.

.DESCRIPTION

    This script retrieves the current Microsoft Defender settings using Get-MpPreference
    and compares them against the recommended policy settings defined in the MDE Security Portal.
    It outputs a compliance report showing which settings match and which need remediation.

.EXAMPLE
    .\Test-DefenderPolicyCompliance.ps1

.EXAMPLE
    .\Test-DefenderPolicyCompliance.ps1 -Verbose

.NOTES
    Requires administrative privileges to read Defender preferences.
    Based on recommended policy from Policies.md
#>

[CmdletBinding()]
param()

#Requires -RunAsAdministrator

# Define the recommended policy settings
# Maps setting names to their expected values and the corresponding MpPreference property
$RecommendedPolicy = @(
    @{
        Name = "Allow Archive Scanning"
        Property = "DisableArchiveScanning"
        ExpectedValue = $false
        ExpectedDisplay = "Allowed"
        Inverted = $true  # DisableArchiveScanning = $false means scanning is allowed
    },
    @{
        Name = "Allow Behavior Monitoring"
        Property = "DisableBehaviorMonitoring"
        ExpectedValue = $false
        ExpectedDisplay = "Allowed"
        Inverted = $true
    },
    @{
        Name = "Allow Cloud Protection"
        Property = "MAPSReporting"
        ExpectedValue = 2  # 0=Disabled, 1=Basic, 2=Advanced
        ExpectedDisplay = "Allowed (Advanced)"
        Inverted = $false
    },
    @{
        Name = "Allow scanning of all downloaded files and attachments"
        Property = "DisableIOAVProtection"
        ExpectedValue = $false
        ExpectedDisplay = "Allowed"
        Inverted = $true
    },
    @{
        Name = "Allow Realtime Monitoring"
        Property = "DisableRealtimeMonitoring"
        ExpectedValue = $false
        ExpectedDisplay = "Allowed"
        Inverted = $true
    },
    @{
        Name = "Allow Script Scanning"
        Property = "DisableScriptScanning"
        ExpectedValue = $false
        ExpectedDisplay = "Allowed"
        Inverted = $true
    },
    @{
        Name = "Cloud Block Level"
        Property = "CloudBlockLevel"
        ExpectedValue = 2  # 0=Default, 1=Moderate, 2=High, 4=High+, 6=Zero tolerance
        ExpectedDisplay = "High"
        Inverted = $false
    },
    @{
        Name = "Enable Network Protection"
        Property = "EnableNetworkProtection"
        ExpectedValue = 1  # 0=Disabled, 1=Enabled (Block), 2=Audit
        ExpectedDisplay = "Enabled (block mode)"
        Inverted = $false
    },
    @{
        Name = "PUA Protection"
        Property = "PUAProtection"
        ExpectedValue = 1  # 0=Disabled, 1=Enabled, 2=Audit
        ExpectedDisplay = "PUA Protection on"
        Inverted = $false
    },
    @{
        Name = "Real Time Scan Direction"
        Property = "RealTimeScanDirection"
        ExpectedValue = 0  # 0=Both directions (all files), 1=Incoming, 2=Outgoing
        ExpectedDisplay = "Monitor all files"
        Inverted = $false
    },
    @{
        Name = "Disable Local Admin Merge"
        Property = "DisableLocalAdminMerge"
        ExpectedValue = $true
        ExpectedDisplay = "Not Allowed (Disabled)"  # Local Admin Merge should be blocked
        Inverted = $true  # Uses Get-AllowedStatus to show "Not Allowed (Disabled)" when $true
    },
    @{
        Name = "Allow On Access Protection"
        Property = "OnAccessProtectionEnabled"
        ExpectedValue = $true
        ExpectedDisplay = "Allowed"
        Inverted = $false
        Source = "ComputerStatus"  # Use Get-MpComputerStatus instead of Get-MpPreference
    },
    @{
        Name = "Remediation action for Severe threats"
        Property = "SevereThreatDefaultAction"
        ExpectedValue = 2  # 1=Clean, 2=Quarantine, 3=Remove, 6=Allow, 8=UserDefined, 9=NoAction, 10=Block
        ExpectedDisplay = "Quarantine"
        Inverted = $false
    },
    @{
        Name = "Remediation action for High threats"
        Property = "HighThreatDefaultAction"
        ExpectedValue = 2
        ExpectedDisplay = "Quarantine"
        Inverted = $false
    },
    @{
        Name = "Remediation action for Moderate threats"
        Property = "ModerateThreatDefaultAction"
        ExpectedValue = 2
        ExpectedDisplay = "Quarantine"
        Inverted = $false
    },
    @{
        Name = "Remediation action for Low threats"
        Property = "LowThreatDefaultAction"
        ExpectedValue = 2
        ExpectedDisplay = "Quarantine"
        Inverted = $false
    },
    @{
        Name = "Allow Network Protection Down Level"
        Property = "AllowNetworkProtectionDownLevel"
        ExpectedValue = $true
        ExpectedDisplay = "Network protection will be enabled down level"
        Inverted = $false
    }
)

# Lookup tables for translating numeric values to friendly names
$CloudBlockLevelMap = @{
    0 = "Default"
    1 = "Moderate"
    2 = "High"
    4 = "High+"
    6 = "Zero tolerance"
}

$NetworkProtectionMap = @{
    0 = "Disabled"
    1 = "Enabled (Block)"
    2 = "Audit"
}

$PUAProtectionMap = @{
    0 = "Disabled"
    1 = "Enabled"
    2 = "Audit"
}

$ScanDirectionMap = @{
    0 = "Both directions (all files)"
    1 = "Incoming files only"
    2 = "Outgoing files only"
}

$ThreatActionMap = @{
    0 = "Default"
    1 = "Clean"
    2 = "Quarantine"
    3 = "Remove"
    6 = "Allow"
    8 = "User Defined"
    9 = "No Action"
    10 = "Block"
}

$MAPSReportingMap = @{
    0 = "Disabled"
    1 = "Basic"
    2 = "Advanced"
}

function Get-FriendlyValue {
    param(
        [string]$PropertyName,
        $Value
    )
    
    $result = $null
    switch ($PropertyName) {
        "CloudBlockLevel" { $result = $CloudBlockLevelMap[$Value] }
        "EnableNetworkProtection" { $result = $NetworkProtectionMap[$Value] }
        "PUAProtection" { $result = $PUAProtectionMap[$Value] }
        "RealTimeScanDirection" { $result = $ScanDirectionMap[$Value] }
        "SevereThreatDefaultAction" { $result = $ThreatActionMap[$Value] }
        "HighThreatDefaultAction" { $result = $ThreatActionMap[$Value] }
        "ModerateThreatDefaultAction" { $result = $ThreatActionMap[$Value] }
        "LowThreatDefaultAction" { $result = $ThreatActionMap[$Value] }
        "MAPSReporting" { $result = $MAPSReportingMap[$Value] }
        default {
            if ($Value -is [bool]) {
                if ($Value) { return "True" } else { return "False" }
            }
            return $Value
        }
    }
    
    if ($null -ne $result) { return $result } else { return $Value }
}

function Get-AllowedStatus {
    param(
        $DisableValue
    )
    
    # Handle null or non-boolean values
    if ($null -eq $DisableValue) {
        return "Unknown (null)"
    }
    
    if ($DisableValue -is [bool]) {
        if ($DisableValue) {
            return "Not Allowed (Disabled)"
        } else {
            return "Allowed"
        }
    }
    
    # Try to convert to boolean for other types
    try {
        $boolValue = [System.Convert]::ToBoolean($DisableValue)
        if ($boolValue) {
            return "Not Allowed (Disabled)"
        } else {
            return "Allowed"
        }
    }
    catch {
        return "Unknown ($DisableValue)"
    }
}

# Main script execution
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host " Microsoft Defender Policy Compliance Check" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

try {
    Write-Verbose "Retrieving Microsoft Defender preferences..."
    $MpPrefs = Get-MpPreference -ErrorAction Stop
}
catch {
    Write-Error "Failed to retrieve Microsoft Defender preferences. Ensure Windows Defender is installed and you have administrative privileges."
    Write-Error $_.Exception.Message
    exit 1
}

try {
    Write-Verbose "Retrieving Microsoft Defender computer status..."
    $MpStatus = Get-MpComputerStatus -ErrorAction Stop
}
catch {
    Write-Error "Failed to retrieve Microsoft Defender computer status."
    Write-Error $_.Exception.Message
    exit 1
}

$Results = @()
$CompliantCount = 0
$NonCompliantCount = 0

foreach ($Setting in $RecommendedPolicy) {
    $PropertyName = $Setting.Property
    
    # Determine which source to use for this setting
    if ($Setting.Source -eq "ComputerStatus") {
        $CurrentValue = $MpStatus.$PropertyName
    } else {
        $CurrentValue = $MpPrefs.$PropertyName
    }
    
    $ExpectedValue = $Setting.ExpectedValue
    
    # Check compliance - handle null values
    if ($null -eq $CurrentValue) {
        $IsCompliant = $false
    } else {
        $IsCompliant = $CurrentValue -eq $ExpectedValue
    }
    
    # Get friendly display values
    if ($Setting.Inverted) {
        Write-Verbose "Processing $($Setting.Name) (Inverted logic) with $CurrentValue"
        $CurrentDisplay = Get-AllowedStatus -DisableValue $CurrentValue
    } elseif ($null -eq $CurrentValue) {
        $CurrentDisplay = "Not Configured (null)"
    } elseif ($CurrentValue -is [bool]) {
        if ($CurrentValue) { $CurrentDisplay = "Enabled" } else { $CurrentDisplay = "Disabled" }
    } else {
        $CurrentDisplay = Get-FriendlyValue -PropertyName $PropertyName -Value $CurrentValue
    }
    
    $Result = [PSCustomObject]@{
        Setting = $Setting.Name
        ExpectedValue = $Setting.ExpectedDisplay
        CurrentValue = $CurrentDisplay
        Compliant = $IsCompliant
        Property = $PropertyName
        RawExpected = $ExpectedValue
        RawCurrent = $CurrentValue
    }
    
    $Results += $Result
    
    if ($IsCompliant) {
        $CompliantCount++
    } else {
        $NonCompliantCount++
    }
}

# Display results
Write-Host "Policy Compliance Results:" -ForegroundColor Yellow
Write-Host "--------------------------`n"

foreach ($Result in $Results) {
    if ($Result.Compliant) {
        Write-Host "[COMPLIANT] " -ForegroundColor Green -NoNewline
        Write-Host "$($Result.Setting)" -NoNewline
        Write-Host " = $($Result.CurrentValue)" -ForegroundColor Gray
    } else {
        Write-Host "[NON-COMPLIANT] " -ForegroundColor Red -NoNewline
        Write-Host "$($Result.Setting)" -ForegroundColor White
        Write-Host "    Expected: " -NoNewline -ForegroundColor Gray
        Write-Host "$($Result.ExpectedValue)" -ForegroundColor Yellow
        Write-Host "    Current:  " -NoNewline -ForegroundColor Gray
        Write-Host "$($Result.CurrentValue)" -ForegroundColor Red
    }
}

# Summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host " Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Total Settings Checked: $($Results.Count)"
Write-Host "Compliant: " -NoNewline
Write-Host "$CompliantCount" -ForegroundColor Green
Write-Host "Non-Compliant: " -NoNewline
Write-Host "$NonCompliantCount" -ForegroundColor Red

$CompliancePercent = [math]::Round(($CompliantCount / $Results.Count) * 100, 1)
Write-Host "Compliance Rate: " -NoNewline
if ($CompliancePercent -eq 100) {
    Write-Host "$CompliancePercent%" -ForegroundColor Green
} elseif ($CompliancePercent -ge 80) {
    Write-Host "$CompliancePercent%" -ForegroundColor Yellow
} else {
    Write-Host "$CompliancePercent%" -ForegroundColor Red
}

# Display Version and Status Information
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host " Defender Version & Status Information" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

Write-Host "`nProduct Information:" -ForegroundColor Yellow
Write-Host "  Product Version:            $($MpStatus.AMProductVersion)"
Write-Host "  Service Version:            $($MpStatus.AMServiceVersion)"

Write-Host "`nPlatform Information:" -ForegroundColor Yellow
Write-Host "  Antimalware Platform Version: $($MpStatus.AMEngineVersion)"
Write-Host "  Platform Update Time:         $($MpStatus.AntispywareSignatureLastUpdated)"

Write-Host "`nSignature Information:" -ForegroundColor Yellow
Write-Host "  Antivirus Signature Version:  $($MpStatus.AntivirusSignatureVersion)"
Write-Host "  Antivirus Signature Age:      $($MpStatus.AntivirusSignatureAge) day(s)"
Write-Host "  Antivirus Last Updated:       $($MpStatus.AntivirusSignatureLastUpdated)"
Write-Host "  Antispyware Signature Version: $($MpStatus.AntispywareSignatureVersion)"
Write-Host "  Antispyware Signature Age:    $($MpStatus.AntispywareSignatureAge) day(s)"
Write-Host "  Antispyware Last Updated:     $($MpStatus.AntispywareSignatureLastUpdated)"

Write-Host "`nEngine Information:" -ForegroundColor Yellow
Write-Host "  Engine Version:               $($MpStatus.AMEngineVersion)"
Write-Host "  NIS Engine Version:           $($MpStatus.NISEngineVersion)"
Write-Host "  NIS Signature Version:        $($MpStatus.NISSignatureVersion)"
Write-Host "  NIS Signature Age:            $($MpStatus.NISSignatureAge) day(s)"
Write-Host "  NIS Last Updated:             $($MpStatus.NISSignatureLastUpdated)"

Write-Host "`nRunning Mode:" -ForegroundColor Yellow
Write-Host "  Antivirus Enabled:            " -NoNewline
if ($MpStatus.AntivirusEnabled) {
    Write-Host "Yes" -ForegroundColor Green
} else {
    Write-Host "No" -ForegroundColor Red
}
Write-Host "  Antispyware Enabled:          " -NoNewline
if ($MpStatus.AntispywareEnabled) {
    Write-Host "Yes" -ForegroundColor Green
} else {
    Write-Host "No" -ForegroundColor Red
}
Write-Host "  Real-Time Protection Enabled: " -NoNewline
if ($MpStatus.RealTimeProtectionEnabled) {
    Write-Host "Yes" -ForegroundColor Green
} else {
    Write-Host "No" -ForegroundColor Red
}
Write-Host "  Behavior Monitor Enabled:     " -NoNewline
if ($MpStatus.BehaviorMonitorEnabled) {
    Write-Host "Yes" -ForegroundColor Green
} else {
    Write-Host "No" -ForegroundColor Red
}
Write-Host "  IoaV Protection Enabled:      " -NoNewline
if ($MpStatus.IoavProtectionEnabled) {
    Write-Host "Yes" -ForegroundColor Green
} else {
    Write-Host "No" -ForegroundColor Red
}
Write-Host "  On Access Protection Enabled: " -NoNewline
if ($MpStatus.OnAccessProtectionEnabled) {
    Write-Host "Yes" -ForegroundColor Green
} else {
    Write-Host "No" -ForegroundColor Red
}

Write-Host "`nTamper Protection:" -ForegroundColor Yellow
Write-Host "  Tamper Protection Enabled:    " -NoNewline
if ($MpStatus.IsTamperProtected) {
    Write-Host "Yes" -ForegroundColor Green
} else {
    Write-Host "No" -ForegroundColor Red
}
Write-Host "  Tamper Protection Source:     $($MpStatus.TamperProtectionSource)"

Write-Host "`nLast Scan Information:" -ForegroundColor Yellow
Write-Host "  Quick Scan End Time:          $($MpStatus.QuickScanEndTime)"
Write-Host "  Quick Scan Age:               $($MpStatus.QuickScanAge) day(s)"
Write-Host "  Full Scan End Time:           $($MpStatus.FullScanEndTime)"
Write-Host "  Full Scan Age:                $($MpStatus.FullScanAge) day(s)"

# Display Exclusions Information
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host " Defender Exclusions" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Helper function to display exclusions with source differentiation
function Show-Exclusions {
    param(
        [string]$Title,
        [array]$AllExclusions,
        [array]$PolicyExclusions
    )
    
    Write-Host "`n$Title`:" -ForegroundColor Yellow
    
    if ($null -eq $AllExclusions -or $AllExclusions.Count -eq 0) {
        Write-Host "  (None configured)" -ForegroundColor Gray
        return
    }
    
    foreach ($exclusion in $AllExclusions) {
        if ($null -ne $PolicyExclusions -and $PolicyExclusions -contains $exclusion) {
            Write-Host "  [Policy] " -ForegroundColor Magenta -NoNewline
            Write-Host "$exclusion"
        } else {
            Write-Host "  [Local]  " -ForegroundColor Cyan -NoNewline
            Write-Host "$exclusion"
        }
    }
}

# Get policy-based exclusions from registry
$PolicyExclusionPaths = @()
$PolicyExclusionExtensions = @()
$PolicyExclusionProcesses = @()
$PolicyExclusionIpAddresses = @()

# Try to read policy exclusions from registry
$PolicyRegBasePath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Exclusions"

try {
    $PathsRegKey = "$PolicyRegBasePath\Paths"
    if (Test-Path $PathsRegKey) {
        $PolicyExclusionPaths = (Get-Item $PathsRegKey -ErrorAction SilentlyContinue).Property
    }
} catch { }

try {
    $ExtensionsRegKey = "$PolicyRegBasePath\Extensions"
    if (Test-Path $ExtensionsRegKey) {
        $PolicyExclusionExtensions = (Get-Item $ExtensionsRegKey -ErrorAction SilentlyContinue).Property
    }
} catch { }

try {
    $ProcessesRegKey = "$PolicyRegBasePath\Processes"
    if (Test-Path $ProcessesRegKey) {
        $PolicyExclusionProcesses = (Get-Item $ProcessesRegKey -ErrorAction SilentlyContinue).Property
    }
} catch { }

try {
    $IpAddressesRegKey = "$PolicyRegBasePath\IpAddresses"
    if (Test-Path $IpAddressesRegKey) {
        $PolicyExclusionIpAddresses = (Get-Item $IpAddressesRegKey -ErrorAction SilentlyContinue).Property
    }
} catch { }

# Also check for Intune/MDM policy exclusions (stored in different location)
$MdmPolicyRegBasePath = "HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Defender"

try {
    if (Test-Path $MdmPolicyRegBasePath) {
        $mdmExclusions = Get-ItemProperty -Path $MdmPolicyRegBasePath -ErrorAction SilentlyContinue
        
        if ($mdmExclusions.ExcludedPaths) {
            $mdmPaths = $mdmExclusions.ExcludedPaths -split '\|'
            $PolicyExclusionPaths += $mdmPaths
        }
        if ($mdmExclusions.ExcludedExtensions) {
            $mdmExtensions = $mdmExclusions.ExcludedExtensions -split '\|'
            $PolicyExclusionExtensions += $mdmExtensions
        }
        if ($mdmExclusions.ExcludedProcesses) {
            $mdmProcesses = $mdmExclusions.ExcludedProcesses -split '\|'
            $PolicyExclusionProcesses += $mdmProcesses
        }
    }
} catch { }

# Get all exclusions from MpPreference
$AllExclusionPaths = $MpPrefs.ExclusionPath
$AllExclusionExtensions = $MpPrefs.ExclusionExtension
$AllExclusionProcesses = $MpPrefs.ExclusionProcess
$AllExclusionIpAddresses = $MpPrefs.ExclusionIpAddress

# Display exclusions with source information
Show-Exclusions -Title "Path Exclusions" -AllExclusions $AllExclusionPaths -PolicyExclusions $PolicyExclusionPaths
Show-Exclusions -Title "Extension Exclusions" -AllExclusions $AllExclusionExtensions -PolicyExclusions $PolicyExclusionExtensions
Show-Exclusions -Title "Process Exclusions" -AllExclusions $AllExclusionProcesses -PolicyExclusions $PolicyExclusionProcesses
Show-Exclusions -Title "IP Address Exclusions" -AllExclusions $AllExclusionIpAddresses -PolicyExclusions $PolicyExclusionIpAddresses

# Display Attack Surface Reduction exclusions if available
Write-Host "`nAttack Surface Reduction Exclusions:" -ForegroundColor Yellow
$AsrExclusions = $MpPrefs.AttackSurfaceReductionOnlyExclusions
if ($null -eq $AsrExclusions -or $AsrExclusions.Count -eq 0) {
    Write-Host "  (None configured)" -ForegroundColor Gray
} else {
    foreach ($exclusion in $AsrExclusions) {
        Write-Host "  $exclusion"
    }
}

# Display Controlled Folder Access allowed applications if available
Write-Host "`nControlled Folder Access Allowed Applications:" -ForegroundColor Yellow
$CfaAllowedApps = $MpPrefs.ControlledFolderAccessAllowedApplications
if ($null -eq $CfaAllowedApps -or $CfaAllowedApps.Count -eq 0) {
    Write-Host "  (None configured)" -ForegroundColor Gray
} else {
    foreach ($app in $CfaAllowedApps) {
        Write-Host "  $app"
    }
}

# Summary of exclusion counts
Write-Host "`nExclusion Summary:" -ForegroundColor Yellow
$pathCount = if ($AllExclusionPaths) { $AllExclusionPaths.Count } else { 0 }
$extCount = if ($AllExclusionExtensions) { $AllExclusionExtensions.Count } else { 0 }
$procCount = if ($AllExclusionProcesses) { $AllExclusionProcesses.Count } else { 0 }
$ipCount = if ($AllExclusionIpAddresses) { $AllExclusionIpAddresses.Count } else { 0 }
$asrCount = if ($AsrExclusions) { $AsrExclusions.Count } else { 0 }
$cfaCount = if ($CfaAllowedApps) { $CfaAllowedApps.Count } else { 0 }

Write-Host "  Path Exclusions:       $pathCount"
Write-Host "  Extension Exclusions:  $extCount"
Write-Host "  Process Exclusions:    $procCount"
Write-Host "  IP Address Exclusions: $ipCount"
Write-Host "  ASR Exclusions:        $asrCount"
Write-Host "  CFA Allowed Apps:      $cfaCount"
Write-Host "  Total Exclusions:      $($pathCount + $extCount + $procCount + $ipCount + $asrCount + $cfaCount)"

# Output object for pipeline usage
Write-Output $Results | Select-Object Setting, ExpectedValue, CurrentValue, Compliant

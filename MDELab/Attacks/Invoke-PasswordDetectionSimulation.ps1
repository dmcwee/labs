param(
    [string]$OutputPath = "$env:Temp\creds",
    [string]$SearchPath = "C:\Users",
    [switch]$CleanUp,
    [switch]$Force
)

# Display information prompt unless Force is specified or in CleanUp mode
if (-not $Force -and -not $CleanUp) {
    Write-Host "`n================================================" -ForegroundColor Cyan
    Write-Host "           ***  INFORMATION  *** " -ForegroundColor Green
    Write-Host "     Password Detection Simulation Script" -ForegroundColor Cyan
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host "`nThis script will search for password-related information:" -ForegroundColor White
    Write-Host "  - Search HKCU registry for 'password' strings" -ForegroundColor Yellow
    Write-Host "  - Search HKLM registry for 'password' strings" -ForegroundColor Yellow
    Write-Host "  - Search files in '$SearchPath' for 'password' strings" -ForegroundColor Yellow
    Write-Host "  - Create a compressed archive of results" -ForegroundColor Yellow
    Write-Host "`nOutput will be saved to: $OutputPath\creds" -ForegroundColor White
    Write-Host "`nThis is for TESTING/SIMULATION purposes only." -ForegroundColor Green
    Write-Host "This activity may trigger security alerts." -ForegroundColor Yellow
    Write-Host "================================================`n" -ForegroundColor Cyan
    
    $response = Read-Host "Do you want to continue? (Y/N)"
    if ($response -notmatch '^[Yy]') {
        Write-Host "Script execution cancelled by user." -ForegroundColor Yellow
        return
    }
    Write-Host ""
}

<#
.SYNOPSIS
Searches registry hives for keys and values containing "password".

.DESCRIPTION
This function recursively searches through HKCU or HKLM registry hives to find any keys,
value names, or value data that contain the word "password". This simulates credential
enumeration techniques used by attackers.

.PARAMETER RegistryHive
The registry hive to search. Valid values are "HKCU" or "HKLM".

.PARAMETER OutputPath
Optional path to save results. If not provided, results are displayed to console only.

.PARAMETER SearchDepth
Maximum depth to search in the registry. Defaults to unlimited (-1).

.EXAMPLE
Search-RegistryPasswords -RegistryHive "HKCU"

.EXAMPLE
Search-RegistryPasswords -RegistryHive "HKLM" -OutputPath "C:\temp\reg_passwords.txt"

.NOTES
Searching HKLM may require administrator privileges for some keys.
This will trigger security alerts in monitored environments.
#>
function Search-RegistryPasswords {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("HKCU", "HKLM")]
        [string]$RegistryHive,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputPath,
        
        [Parameter(Mandatory = $false)]
        [int]$SearchDepth = -1
    )
    
    try {
        Write-Host "`nSearching $RegistryHive registry hive for password-related entries..." -ForegroundColor Yellow
        
        $results = @()
        $searchPattern = "password"
        
        # Get the root registry path
        $rootPath = "$($RegistryHive):\"
        
        # Function to recursively search registry
        function Search-RegistryKey {
            param(
                [string]$Path,
                [int]$CurrentDepth = 0
            )
            
            if ($SearchDepth -ne -1 -and $CurrentDepth -gt $SearchDepth) {
                return
            }
            
            try {
                $key = Get-Item -Path $Path -ErrorAction SilentlyContinue
                
                if ($null -eq $key) {
                    return
                }
                
                # Check if key name contains "password"
                if ($key.PSPath -match $searchPattern) {
                    $results += [PSCustomObject]@{
                        Type = "KeyName"
                        Path = $key.PSPath
                        Name = $key.PSChildName
                        Value = ""
                    }
                    Write-Host "  [KEY] $($key.PSPath)" -ForegroundColor Cyan
                }
                
                # Check each property (value) in the key
                foreach ($valueName in $key.GetValueNames()) {
                    $valueData = $key.GetValue($valueName)
                    
                    # Check if value name contains "password"
                    if ($valueName -match $searchPattern) {
                        $results += [PSCustomObject]@{
                            Type = "ValueName"
                            Path = $key.PSPath
                            Name = $valueName
                            Value = $valueData
                        }
                        Write-Host "  [VALUE] $($key.PSPath)\$valueName = $valueData" -ForegroundColor Green
                    }
                    # Check if value data contains "password"
                    elseif ($valueData -is [string] -and $valueData -match $searchPattern) {
                        $results += [PSCustomObject]@{
                            Type = "ValueData"
                            Path = $key.PSPath
                            Name = $valueName
                            Value = $valueData
                        }
                        Write-Host "  [DATA] $($key.PSPath)\$valueName = $valueData" -ForegroundColor Magenta
                    }
                }
                
                # Recursively search subkeys
                foreach ($subKeyName in $key.GetSubKeyNames()) {
                    $subKeyPath = Join-Path -Path $Path -ChildPath $subKeyName
                    Search-RegistryKey -Path $subKeyPath -CurrentDepth ($CurrentDepth + 1)
                }
            }
            catch {
                # Silently skip access denied errors
                if ($_.Exception.Message -notmatch "access.*denied|Requested registry access") {
                    Write-Verbose "Error accessing $Path : $_"
                }
            }
        }
        
        # Start the search
        Search-RegistryKey -Path $rootPath
        
        Write-Host "`nSearch complete. Found $($results.Count) matches." -ForegroundColor Yellow
        
        # Save results if output path is provided
        if ($OutputPath) {
            $results | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
            Write-Host "Results saved to: $OutputPath" -ForegroundColor Green
        }
        
        return $results
    }
    catch {
        Write-Error "Failed to search registry: $_"
        return $null
    }
}

if($CleanUp) {
    if (Test-Path -Path $OutputPath) {
        Write-Host "Cleaning up output directory: $OutputPath" -ForegroundColor Yellow
        Remove-Item -Path $OutputPath -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "Cleanup completed." -ForegroundColor Green
    }
    else {
        Write-Host "Output directory does not exist. Nothing to clean up." -ForegroundColor Gray
    }
}
else {
    # Ensure output directory exists
    if (-not (Test-Path -Path $OutputPath)) {
        Write-Host "Creating output directory: $OutputPath" -ForegroundColor Cyan
        New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    }
    else {
        Write-Host "Output directory already exists: $OutputPath" -ForegroundColor Gray
    }

    # Verify directory was created successfully
    if (-not (Test-Path -Path $OutputPath)) {
        Write-Error "Failed to create output directory: $OutputPath"
        return
    }

    reg query HKCU /f password /t REG_SZ /s > "$OutputPath\HKCU_Passwords.txt"
    reg query HKLM /f password /t REG_SZ /s > "$OutputPath\HKLM_Passwords.txt"

    $zipFilePath = "$OutputPath\passwords.zip"
    Compress-Archive -Path $OutputPath -DestinationPath $zipFilePath -Force

    #findstr /s /i /m "password" *.*
    Get-ChildItem -Path $SearchPath -Recurse -File -ErrorAction SilentlyContinue | 
        Select-String -Pattern "password" -ErrorAction SilentlyContinue | 
        Select-Object -ExpandProperty Path -Unique |
        Out-File -FilePath "$OutputPath\password_search_results.txt" -Encoding utf8
}
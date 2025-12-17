param(
    [string]$OutputPath = "$env:TEMP\Discovery",
    [Switch]$CleanUp,
    [Switch]$Force
)

# Check if machine is domain joined
$isDomainJoined = (Get-CimInstance -ClassName Win32_ComputerSystem).PartOfDomain

# Display information prompt unless Force is specified or in CleanUp mode
if (-not $Force -and -not $CleanUp) {
    Write-Host "`n================================================" -ForegroundColor Cyan
    Write-Host "              ***  INFORMATION  *** " -ForegroundColor Green
    Write-Host "      Account Discovery Simulation Script" -ForegroundColor Cyan
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host "`nThis script will perform account enumeration activities that may be detected as suspicious:" -ForegroundColor White
    Write-Host "  - Enumerate all local users and groups" -ForegroundColor Cyan
    Write-Host "  - Enumerate local group memberships" -ForegroundColor Cyan
    
    # Check if machine is domain joined to determine what else will be enumerated
    if ($isDomainJoined) {
        Write-Host "  - Enumerate all domain users" -ForegroundColor Cyan
        Write-Host "  - Enumerate Domain Admins group members" -ForegroundColor Cyan
        Write-Host "  - Enumerate Enterprise Admins group members" -ForegroundColor Cyan
    }
    
    Write-Host "`nOutput will be saved to: $OutputPath" -ForegroundColor White
    Write-Host "`nThis is for TESTING/SIMULATION purposes only." -ForegroundColor Green
    Write-Host "================================================`n" -ForegroundColor Cyan
    
    $response = Read-Host "Do you want to continue? (Y/N)"
    if ($response -notmatch '^[Yy]') {
        Write-Host "Script execution cancelled by user." -ForegroundColor Yellow
        return
    }
    Write-Host ""
}



if($CleanUp) {
    Remove-Item -Path $OutputPath -Recurse -Force
}
else {
    if(-not (Test-Path -Path $OutputPath)) {
        New-Item -Path $OutputPath -ItemType Directory -ErrorAction SilentlyContinue
    }

    # Enumerate Local Users
    Write-Output "Enumerating Local Users..."
    Get-LocalUser | Format-Table -Property Name,Enabled,Description | Out-File -FilePath $("$OutputPath\Users.txt") -Encoding utf8

    # Enumerate Local Groups
    Write-Output "Enumerating Local Groups..."
    $localGroups = Get-LocalGroup 
    $localGroups | Format-Table -Property Name,Description | Out-File -FilePath $("$OutputPath\Groups.txt")

    $localGroups | ForEach-Object { Get-LocalGroupMember -Group $_ | Out-File -FilePath $("$OutputPath\$_-Members.txt") -Encoding utf8 }

    if(-not $isDomainJoined) {
        Write-Information "Machine is not domain joined. Skipping domain enumeration."
    }
    else {
        # Check if ActiveDirectory module is available
        if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
            Write-Warning "ActiveDirectory PowerShell module not found. Attempting to install..."
            
            try {
                # Check if running as administrator
                $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
                
                if (-not $isAdmin) {
                    Write-Error "Installing RSAT tools requires administrator privileges. Please run as administrator."
                    return
                }
                
                # Install RSAT-AD-PowerShell feature (Windows 10/11 and Windows Server)
                $osInfo = Get-CimInstance -ClassName Win32_OperatingSystem
                if ($osInfo.ProductType -eq 1) {
                    # Client OS (Windows 10/11)
                    Write-Host "Installing RSAT Active Directory PowerShell module..."
                    Add-WindowsCapability -Online -Name Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0 -ErrorAction Stop
                } else {
                    # Server OS
                    Write-Host "Installing Active Directory PowerShell module..."
                    Install-WindowsFeature -Name RSAT-AD-PowerShell -ErrorAction Stop
                }
                
                Write-Host "ActiveDirectory module installed successfully." -ForegroundColor Green
            }
            catch {
                Write-Error "Failed to install ActiveDirectory module: $_"
                Write-Warning "Skipping domain enumeration."
                return
            }
        }
        
        # Import the ActiveDirectory module
        Import-Module ActiveDirectory -ErrorAction Stop
        
        $DomainPath = "$OutputPath\Domain"
        if(-not (Test-Path -Path $DomainPath)) {
            New-Item -Path $OutputPath -ItemType Directory -ErrorAction SilentlyContinue
        }

        Get-ADUser -Filter * -Property DisplayName, Enabled, SamAccountName | Format-Table -Property DisplayName, SamAccountName, Name | Out-File -FilePath "$OutputPath\domain-users.txt" -Encoding utf8

        # Fetch membership of "Domain Admins" and "Enterprise Admins"
        Get-ADGroupMember -Identity "Domain Admins" | Format-Table -Property SamAccountName, Name | Out-File -FilePath "$OutputPath\domain-admins.txt" -Encoding utf8
        Get-ADGroupMember -Identity "Enterprise Admins" | Format-Table -Property SamAccountName, Name | Out-File -FilePath "$OutputPath\enterprise-admins.txt" -Encoding utf8
    }
}
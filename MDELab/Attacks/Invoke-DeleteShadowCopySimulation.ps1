param(
    [ValidateSet("WMIC", "VSSAdmin", "PowerShell")]
    [string]$Method = "WMIC",
    [switch]$Force
)

# Display warning prompt unless Force is specified
if (-not $Force) {
    Write-Host "`n================================================" -ForegroundColor Yellow
    Write-Host "                ***  WARNING  *** " -ForegroundColor Red
    Write-Host "    Shadow Copy Deletion Simulation Script" -ForegroundColor Yellow
    Write-Host "================================================" -ForegroundColor Yellow
    Write-Host "`nThis script will delete shadow copies and backup catalogs:" -ForegroundColor White
    Write-Host "  - Delete ALL shadow copies on the system" -ForegroundColor Cyan
    Write-Host "  - Delete Windows backup catalog" -ForegroundColor Cyan
    Write-Host "`nMethod: $Method" -ForegroundColor White
    Write-Host "`nThis is for TESTING/SIMULATION purposes only." -ForegroundColor Red
    Write-Host "This action is commonly associated with ransomware behavior." -ForegroundColor Red
    Write-Host "================================================`n" -ForegroundColor Yellow
    
    $response = Read-Host "Do you want to continue? (Y/N)"
    if ($response -notmatch '^[Yy]') {
        Write-Host "Script execution cancelled by user." -ForegroundColor Yellow
        return
    }
    Write-Host ""
}

# Check for administrator privileges
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Error "This script requires administrator privileges. Please run as Administrator."
    return
}

switch ($Method) {
    "WMIC" {
        Write-Host "Using WMIC method..." -ForegroundColor Yellow
        Write-Host "Note: WMIC is deprecated in Windows 10 20H1+ and removed in Windows 11" -ForegroundColor Gray
        
        # Delete shadow copies using WMIC
        Write-Host "Deleting shadow copies..." -ForegroundColor Cyan
        wmic.exe shadowcopy delete /nointeractive
        
        # Delete backup catalog
        Write-Host "Deleting backup catalog..." -ForegroundColor Cyan
        wbadmin delete catalog -quiet
        
        Write-Host "WMIC method completed." -ForegroundColor Green
    }
    
    "VSSAdmin" {
        Write-Host "Using VSSAdmin method..." -ForegroundColor Yellow
        
        # Delete shadow copies using vssadmin
        Write-Host "Deleting shadow copies..." -ForegroundColor Cyan
        vssadmin.exe delete shadows /all /quiet
        
        # Delete backup catalog
        Write-Host "Deleting backup catalog..." -ForegroundColor Cyan
        wbadmin delete catalog -quiet
        
        Write-Host "VSSAdmin method completed." -ForegroundColor Green
    }
    
    "PowerShell" {
        Write-Host "Using PowerShell method..." -ForegroundColor Yellow
        
        # Delete shadow copies using PowerShell CIM cmdlets
        Write-Host "Deleting shadow copies..." -ForegroundColor Cyan
        try {
            $shadowCopies = Get-CimInstance -ClassName Win32_ShadowCopy -ErrorAction Stop
            if ($shadowCopies) {
                $count = ($shadowCopies | Measure-Object).Count
                $shadowCopies | Remove-CimInstance -ErrorAction Stop
                Write-Host "Deleted $count shadow copy(ies)" -ForegroundColor Yellow
            } else {
                Write-Host "No shadow copies found" -ForegroundColor Gray
            }
        } catch {
            Write-Error "Failed to delete shadow copies: $_"
        }
        
        # Delete backup catalog (no PowerShell cmdlet available, using wbadmin)
        Write-Host "Deleting backup catalog..." -ForegroundColor Cyan
        try {
            Start-Process -FilePath "wbadmin.exe" -ArgumentList "delete catalog -quiet" -NoNewWindow -Wait -ErrorAction Stop
        } catch {
            Write-Error "Failed to delete backup catalog: $_"
        }
        
        Write-Host "PowerShell method completed." -ForegroundColor Green
    }
}

Write-Host "`nShadow copy deletion simulation complete." -ForegroundColor Yellow
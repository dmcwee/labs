[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$Domain,

    [Parameter(Mandatory = $false)]
    [string]$NameServer,

    [Parameter(Mandatory = $false)]
    [string]$OutputPath = "$env:TEMP\DnsZoneTransfer",

    [Parameter(Mandatory = $false)]
    [int]$TimeoutSec = 15,

    [Parameter(Mandatory = $false)]
    [string[]]$RecordTypes = @('UNKNOWN', 'A_AAAA', 'A', 'NS', 'MD', 'MF', ' CNAME', 'SOA', 'MB', 'MG', 'MR', 'NULL', 'WKS', 'PTR', 'HINFO', 'MINFO', 'MX', 'TXT', 'RP', 'AFSDB', 'X25', 'ISDN',
    'RT', 'AAAA', 'SRV', 'DNAME', 'OPT', 'DS', 'RRSIG', 'NSEC', 'DNSKEY', 'DHCID', 'NSEC3', 'NSEC3PARAM', 'ANY', 'ALL', 'WINS'),

    [Parameter(Mandatory = $false)]
    [switch]$CleanUp,

    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Banner and prompt (unless Force is specified)
if (-not $Force) {
    Write-Host "" -ForegroundColor Cyan
    Write-Host "===============================================" -ForegroundColor Cyan
    Write-Host "   DNS Zone Transfer & Record Enumeration Tool" -ForegroundColor Cyan
    Write-Host "===============================================" -ForegroundColor Cyan
    Write-Host "Domain: $Domain" -ForegroundColor Yellow
    Write-Host "Output Path: $OutputPath" -ForegroundColor Yellow
    Write-Host "Record Types: $($RecordTypes -join ', ')" -ForegroundColor Yellow
    if ($NameServer) {
        Write-Host "Name Server: $NameServer" -ForegroundColor Yellow
    } else {
        Write-Host "Name Server: (auto-discover)" -ForegroundColor Yellow
    }
    Write-Host "Timeout (sec): $TimeoutSec" -ForegroundColor Yellow
    Write-Host "" -ForegroundColor Cyan
    Write-Host "This script will attempt to enumerate DNS records and perform a zone transfer if possible." -ForegroundColor White
    Write-Host "Output will be saved to the specified path." -ForegroundColor White
    Write-Host "" -ForegroundColor Cyan
    $resp = Read-Host "Do you want to continue? (Y/N)"
    if ($resp -notmatch '^(Y|y)') {
        Write-Host "Aborted by user." -ForegroundColor Red
        exit 0
    }
}
# If cleanup only, delete matching output files and exit
if ($CleanUp) {
    Write-Host "[*] CleanUp requested. Removing previous output files from $OutputPath" -ForegroundColor Yellow
    Remove-Item -Path $OutputPath -Recurse -Force
}
else {
    if(-not (Test-Path -Path $OutputPath)) {
        New-Item -Path $OutputPath -ItemType Directory -ErrorAction SilentlyContinue
    }
    
    # Discover name servers if not provided
    if (-not $NameServer) {
        Write-Host "[*] Discovering NS records for $Domain" -ForegroundColor Cyan
        try {
            $nsRecords = Resolve-DnsName -Name $Domain -Type NS -ErrorAction Stop
            $nsCandidates = $nsRecords | Select-Object -ExpandProperty NameHost -Unique
        } catch {
            Write-Warning "Failed to resolve NS records: $_"
            $nsCandidates = @()
        }
    } else {
        $nsCandidates = @($NameServer)
    }

    if (-not $nsCandidates -or $nsCandidates.Count -eq 0) {
        Write-Warning "No name servers available to test. Exiting." -ForegroundColor Yellow
        exit 2
    }

    foreach ($ns in $nsCandidates) {
        $filePath = "$OutputPath\ResolveDnsName_$ns.txt"

        # If RecordTypes was provided empty, fall back to defaults
        if (-not $RecordTypes -or $RecordTypes.Count -eq 0) {
            $typesToQuery = @('TXT','NS','CNAME','MX', 'NULL', 'SOA')
        }
        else {
            $typesToQuery = $RecordTypes
        }

        foreach($dnsType in $typesToQuery) {
            $resolveParams = @{
                Name = $Domain
                Server = $ns
                Type = $dnsType
                ErrorAction = 'SilentlyContinue'
            }

            if(Test-Path -Path $filePath) {
                "--- $dnsType ---" | Out-File -FilePath $filePath -Encoding UTF8 -Append
            }
            else {
                "--- $dnsType ---" | Out-File -FilePath $filePath -Encoding UTF8
            }
            
            $output = Resolve-DnsName @resolveParams

            if($output) {
                Write-Host "[+] DNS Resolve from $ns for $dnsType succeeded" -ForegroundColor Green
                $output | Out-File -FilePath $filePath -Encoding UTF8 -Append
            }
            else {
                Write-Host "[-] DNS Resolve from $ns for $dnsType failed or returned no results" -ForegroundColor Red
                "  >> No results <<" | Out-File -FilePath $filePath -Encoding UTF8 -Append
            }
        }
    }
}
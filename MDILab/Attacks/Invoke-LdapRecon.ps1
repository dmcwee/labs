[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = "$env:TEMP\LdapRecon",

    [Parameter(Mandatory = $false)]
    [string]$DomainController = "DC1",

    [Parameter(Mandatory = $false)]
    [int]$Port = 389,

    [Parameter(Mandatory = $false)]
    [switch]$UseSSL,

    [Parameter(Mandatory = $false)]
    [string]$Username = "Administrator",

    [Parameter(Mandatory = $false)]
    [securestring]$Password,

    [Parameter(Mandatory = $false)]
    [string]$DomainName = "contoso.com", # This is now the domain name, e.g. contoso.com

    [Parameter(Mandatory = $false)]
    [switch]$CleanUp
)

# Convert domain name in $SearchBase to LDAP DN format
function Convert-DomainToDN {
    param([string]$DomainName)
    $parts = $DomainName -split '\.'
    $dn = ''
    foreach ($p in $parts) { $dn += "DC=$p," }
    return $dn.TrimEnd(',')
}

# Function to perform LDAP search
function Invoke-LdapSearch {
    param(
        [System.DirectoryServices.Protocols.LdapConnection]$Connection,
        [string]$SearchBase,
        [string]$Filter,
        [string[]]$Attributes,
        [System.DirectoryServices.Protocols.SearchScope]$Scope = [System.DirectoryServices.Protocols.SearchScope]::Subtree
    )

    try {
        $searchRequest = New-Object System.DirectoryServices.Protocols.SearchRequest(
            $SearchBase,
            $Filter,
            $Scope,
            $Attributes
        )
    
        # Set page size for large result sets
        $pageControl = New-Object System.DirectoryServices.Protocols.PageResultRequestControl(1000)
        $searchRequest.Controls.Add($pageControl) | Out-Null
    
        $results = @()
    
        while ($true) {
            $searchResponse = $Connection.SendRequest($searchRequest)
        
            if ($searchResponse.ResultCode -ne [System.DirectoryServices.Protocols.ResultCode]::Success) {
                Write-Warning "Search failed with result code: $($searchResponse.ResultCode)"
                break
            }
        
            foreach ($entry in $searchResponse.Entries) {
                $obj = @{}
            
                foreach ($attr in $entry.Attributes.Keys) {
                    $values = $entry.Attributes[$attr]
                    if ($values.Count -eq 1) {
                        # Handle binary attributes
                        if ($values[0] -is [byte[]]) {
                            $obj[$attr] = [System.Convert]::ToBase64String($values[0])
                        }
                        else {
                            $obj[$attr] = $values[0]
                        }
                    }
                    else {
                        $obj[$attr] = $values.GetValues([string]) -join ";"
                    }
                }
            
                $results += [PSCustomObject]$obj
            }
        
            # Check if there are more pages
            $pageResponse = $searchResponse.Controls | Where-Object { $_ -is [System.DirectoryServices.Protocols.PageResultResponseControl] }
            if ($null -eq $pageResponse -or $pageResponse.Cookie.Length -eq 0) {
                break
            }
        
            $pageControl.Cookie = $pageResponse.Cookie
        }
    
        return $results
    }
    catch {
        Write-Warning "LDAP search error: $_"
        return @()
    }
}

if ($CleanUp) {
    Remove-Item -Path $OutputPath -Recurse -Force
    Write-Host "[*] Cleaned up output directory: $OutputPath" -ForegroundColor Green
    return
}
else {
    # Load required assemblies
    Add-Type -AssemblyName System.DirectoryServices.Protocols
    Add-Type -AssemblyName System.Net

    Write-Host "[*] LDAP Reconnaissance Script" -ForegroundColor Cyan
    Write-Host "[*] Using System.DirectoryServices.Protocols for direct LDAP queries" -ForegroundColor Cyan

    # Create output directory if it doesn't exist
    if (-not (Test-Path -Path $OutputPath)) {
        try {
            New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
            Write-Host "[+] Created output directory: $OutputPath" -ForegroundColor Green
        }
        catch {
            Write-Error "Failed to create output directory: $_"
            exit 1
        }
    }

    $SearchBase = Convert-DomainToDN -DomainName $DomainName
    Write-Host "[+] Using search base: $SearchBase" -ForegroundColor Green

    # Discover domain controller if not specified
    if (-not $DomainController) {
        Write-Host "[*] No domain controller specified, attempting DNS discovery..." -ForegroundColor Cyan
        try {
            $domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
            $DomainController = $domain.FindDomainController().Name
            Write-Host "[+] Discovered domain controller: $DomainController" -ForegroundColor Green
        }
        catch {
            Write-Error "Failed to discover domain controller. Please specify -DomainController parameter."
            exit 1
        }
    }

    # Set port based on SSL
    if ($UseSSL -and $Port -eq 389) {
        $Port = 636
    }

    Write-Host "[*] Target: $DomainController`:$Port" -ForegroundColor Cyan
    Write-Host "[*] SSL: $UseSSL" -ForegroundColor Cyan

    # Create LDAP connection
    try {
        $ldapIdentifier = New-Object System.DirectoryServices.Protocols.LdapDirectoryIdentifier($DomainController, $Port)
        $ldapConnection = New-Object System.DirectoryServices.Protocols.LdapConnection($ldapIdentifier)
    
        # Configure SSL if requested
        if ($UseSSL) {
            $ldapConnection.SessionOptions.SecureSocketLayer = $true
            $ldapConnection.SessionOptions.VerifyServerCertificate = { $true }
        }
    
        # Set authentication
        if ($Username -and $Password) {
            $credential = New-Object System.Net.NetworkCredential($Username, $Password)
            $ldapConnection.Credential = $credential
            Write-Host "[*] Using explicit credentials for: $Username" -ForegroundColor Cyan
        }
        else {
            $ldapConnection.AuthType = [System.DirectoryServices.Protocols.AuthType]::Negotiate
            Write-Host "[*] Using current user credentials" -ForegroundColor Cyan
        }
    
        # Test connection
        $ldapConnection.Bind()
        Write-Host "[+] Successfully connected to LDAP server" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to connect to LDAP server: $_"
        exit 1
    }

    # Export domain information
    Write-Host "[*] Querying domain information..." -ForegroundColor Cyan
    $domainInfo = Invoke-LdapSearch -Connection $ldapConnection -SearchBase $SearchBase -Filter "(objectClass=domain)" -Attributes @("distinguishedName", "name", "objectSid", "whenCreated", "whenChanged")
    if ($domainInfo.Count -gt 0) {
        $domainInfo | Export-Csv -Path "$OutputPath\DomainInfo.csv" -NoTypeInformation
        Write-Host "[+] Exported domain information to DomainInfo.csv" -ForegroundColor Green
    }

    # Export Organizational Units
    Write-Host "[*] Querying Organizational Units..." -ForegroundColor Cyan
    $ouAttributes = @(
        "distinguishedName", "name", "description", "ou", "whenCreated", "whenChanged",
        "managedBy", "gPLink", "objectGUID"
    )
    $ous = Invoke-LdapSearch -Connection $ldapConnection -SearchBase $SearchBase -Filter "(objectClass=organizationalUnit)" -Attributes $ouAttributes
    if ($ous.Count -gt 0) {
        $ous | Export-Csv -Path "$OutputPath\OrganizationalUnits.csv" -NoTypeInformation
        Write-Host "[+] Exported $($ous.Count) OUs to OrganizationalUnits.csv" -ForegroundColor Green
    }

    # Export Users
    Write-Host "[*] Querying Users..." -ForegroundColor Cyan
    $userAttributes = @(
        "distinguishedName", "sAMAccountName", "userPrincipalName", "name", "displayName",
        "givenName", "sn", "mail", "description", "userAccountControl", "pwdLastSet",
        "lastLogonTimestamp", "badPwdCount", "badPasswordTime", "logonCount",
        "whenCreated", "whenChanged", "objectSid", "objectGUID", "memberOf",
        "primaryGroupID", "title", "department", "company", "manager",
        "adminCount", "servicePrincipalName", "userWorkstations"
    )
    $users = Invoke-LdapSearch -Connection $ldapConnection -SearchBase $SearchBase -Filter "(&(objectCategory=person)(objectClass=user))" -Attributes $userAttributes
    if ($users.Count -gt 0) {
        # Decode userAccountControl flags
        $users | ForEach-Object {
            if ($_.userAccountControl) {
                $uac = [int]$_.userAccountControl
                $_ | Add-Member -NotePropertyName "UAC_ACCOUNTDISABLE" -NotePropertyValue (($uac -band 0x0002) -ne 0)
                $_ | Add-Member -NotePropertyName "UAC_DONT_REQUIRE_PREAUTH" -NotePropertyValue (($uac -band 0x400000) -ne 0)
                $_ | Add-Member -NotePropertyName "UAC_PASSWORD_NOT_REQUIRED" -NotePropertyValue (($uac -band 0x0020) -ne 0)
                $_ | Add-Member -NotePropertyName "UAC_TRUSTED_FOR_DELEGATION" -NotePropertyValue (($uac -band 0x80000) -ne 0)
            }
        }
        $users | Export-Csv -Path "$OutputPath\Users.csv" -NoTypeInformation
        Write-Host "[+] Exported $($users.Count) users to Users.csv" -ForegroundColor Green
    }

    # Export Groups
    Write-Host "[*] Querying Groups..." -ForegroundColor Cyan
    $groupAttributes = @(
        "distinguishedName", "sAMAccountName", "name", "description", "groupType",
        "member", "memberOf", "managedBy", "whenCreated", "whenChanged",
        "objectSid", "objectGUID", "adminCount"
    )
    $groups = Invoke-LdapSearch -Connection $ldapConnection -SearchBase $SearchBase -Filter "(objectClass=group)" -Attributes $groupAttributes
    if ($groups.Count -gt 0) {
        $groups | Export-Csv -Path "$OutputPath\Groups.csv" -NoTypeInformation
        Write-Host "[+] Exported $($groups.Count) groups to Groups.csv" -ForegroundColor Green
    }

    # Export Computers
    Write-Host "[*] Querying Computers..." -ForegroundColor Cyan
    $computerAttributes = @(
        "distinguishedName", "sAMAccountName", "dNSHostName", "name", "description",
        "operatingSystem", "operatingSystemVersion", "operatingSystemServicePack",
        "lastLogonTimestamp", "pwdLastSet", "whenCreated", "whenChanged",
        "userAccountControl", "objectSid", "objectGUID", "servicePrincipalName",
        "memberOf", "primaryGroupID"
    )
    $computers = Invoke-LdapSearch -Connection $ldapConnection -SearchBase $SearchBase -Filter "(objectClass=computer)" -Attributes $computerAttributes
    if ($computers.Count -gt 0) {
        $computers | Export-Csv -Path "$OutputPath\Computers.csv" -NoTypeInformation
        Write-Host "[+] Exported $($computers.Count) computers to Computers.csv" -ForegroundColor Green
    }

    # Export Service Principal Names (SPNs)
    Write-Host "[*] Querying Service Principal Names..." -ForegroundColor Cyan
    $spnObjects = Invoke-LdapSearch -Connection $ldapConnection -SearchBase $SearchBase -Filter "(servicePrincipalName=*)" -Attributes @("distinguishedName", "sAMAccountName", "servicePrincipalName", "objectClass")
    if ($spnObjects.Count -gt 0) {
        $spnObjects | Export-Csv -Path "$OutputPath\ServicePrincipalNames.csv" -NoTypeInformation
        Write-Host "[+] Exported $($spnObjects.Count) objects with SPNs to ServicePrincipalNames.csv" -ForegroundColor Green
    }

    # Export Privileged Users (adminCount=1)
    Write-Host "[*] Querying Privileged Users..." -ForegroundColor Cyan
    $privUsers = Invoke-LdapSearch -Connection $ldapConnection -SearchBase $SearchBase -Filter "(&(objectCategory=person)(objectClass=user)(adminCount=1))" -Attributes $userAttributes
    if ($privUsers.Count -gt 0) {
        $privUsers | Export-Csv -Path "$OutputPath\PrivilegedUsers.csv" -NoTypeInformation
        Write-Host "[+] Exported $($privUsers.Count) privileged users to PrivilegedUsers.csv" -ForegroundColor Green
    }

    # Export Domain Controllers
    Write-Host "[*] Querying Domain Controllers..." -ForegroundColor Cyan
    $dcs = Invoke-LdapSearch -Connection $ldapConnection -SearchBase $SearchBase -Filter "(&(objectCategory=computer)(userAccountControl:1.2.840.113556.1.4.803:=8192))" -Attributes $computerAttributes
    if ($dcs.Count -gt 0) {
        $dcs | Export-Csv -Path "$OutputPath\DomainControllers.csv" -NoTypeInformation
        Write-Host "[+] Exported $($dcs.Count) domain controllers to DomainControllers.csv" -ForegroundColor Green
    }

    # Export Trusts
    Write-Host "[*] Querying Domain Trusts..." -ForegroundColor Cyan
    $trustAttributes = @("distinguishedName", "name", "trustPartner", "trustDirection", "trustType", "trustAttributes", "whenCreated", "whenChanged")
    $trusts = Invoke-LdapSearch -Connection $ldapConnection -SearchBase $SearchBase -Filter "(objectClass=trustedDomain)" -Attributes $trustAttributes
    if ($trusts.Count -gt 0) {
        $trusts | Export-Csv -Path "$OutputPath\DomainTrusts.csv" -NoTypeInformation
        Write-Host "[+] Exported $($trusts.Count) domain trusts to DomainTrusts.csv" -ForegroundColor Green
    }

    # Export GPOs from Configuration NC
    Write-Host "[*] Querying Group Policy Objects..." -ForegroundColor Cyan
    $gpoSearchBase = "CN=Policies,CN=System,$SearchBase"
    $gpoAttributes = @("distinguishedName", "displayName", "name", "gPCFileSysPath", "versionNumber", "flags", "whenCreated", "whenChanged")
    $gpos = Invoke-LdapSearch -Connection $ldapConnection -SearchBase $gpoSearchBase -Filter "(objectClass=groupPolicyContainer)" -Attributes $gpoAttributes
    if ($gpos.Count -gt 0) {
        $gpos | Export-Csv -Path "$OutputPath\GroupPolicyObjects.csv" -NoTypeInformation
        Write-Host "[+] Exported $($gpos.Count) GPOs to GroupPolicyObjects.csv" -ForegroundColor Green
    }

    # Export All Objects (high-level overview)
    Write-Host "[*] Querying all objects..." -ForegroundColor Cyan
    $allAttributes = @("distinguishedName", "name", "objectClass", "objectCategory", "whenCreated", "whenChanged")
    $allObjects = Invoke-LdapSearch -Connection $ldapConnection -SearchBase $SearchBase -Filter "(objectClass=*)" -Attributes $allAttributes
    if ($allObjects.Count -gt 0) {
        $allObjects | Export-Csv -Path "$OutputPath\AllObjects.csv" -NoTypeInformation
        Write-Host "[+] Exported $($allObjects.Count) total objects to AllObjects.csv" -ForegroundColor Green
    }

    # Generate statistics
    Write-Host "[*] Generating statistics..." -ForegroundColor Cyan
    $statistics = [PSCustomObject]@{
        Timestamp           = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        DomainController    = $DomainController
        Port                = $Port
        SSL                 = $UseSSL
        SearchBase          = $SearchBase
        TotalObjects        = $allObjects.Count
        OrganizationalUnits = $ous.Count
        Users               = $users.Count
        PrivilegedUsers     = $privUsers.Count
        Groups              = $groups.Count
        Computers           = $computers.Count
        DomainControllers   = $dcs.Count
        ObjectsWithSPNs     = $spnObjects.Count
        GroupPolicyObjects  = $gpos.Count
        DomainTrusts        = $trusts.Count
    }

    $statistics | Export-Csv -Path "$OutputPath\Statistics.csv" -NoTypeInformation
    Write-Host "[+] Exported statistics to Statistics.csv" -ForegroundColor Green

    # Close connection
    $ldapConnection.Dispose()

    # Display summary
    Write-Host "`n================================" -ForegroundColor Cyan
    Write-Host "LDAP Reconnaissance Complete!" -ForegroundColor Green
    Write-Host "================================" -ForegroundColor Cyan
    Write-Host "Output Location: $OutputPath" -ForegroundColor Yellow
    Write-Host "`nTarget Information:" -ForegroundColor Cyan
    Write-Host "  Domain Controller: $DomainController`:$Port" -ForegroundColor White
    Write-Host "  Search Base: $SearchBase" -ForegroundColor White
    Write-Host "  SSL Enabled: $UseSSL" -ForegroundColor White
    Write-Host "`nDiscovery Summary:" -ForegroundColor Cyan
    Write-Host "  Total Objects: $($statistics.TotalObjects)" -ForegroundColor White
    Write-Host "  Organizational Units: $($statistics.OrganizationalUnits)" -ForegroundColor White
    Write-Host "  Users: $($statistics.Users)" -ForegroundColor White
    Write-Host "  Privileged Users: $($statistics.PrivilegedUsers)" -ForegroundColor White
    Write-Host "  Groups: $($statistics.Groups)" -ForegroundColor White
    Write-Host "  Computers: $($statistics.Computers)" -ForegroundColor White
    Write-Host "  Domain Controllers: $($statistics.DomainControllers)" -ForegroundColor White
    Write-Host "  Objects with SPNs: $($statistics.ObjectsWithSPNs)" -ForegroundColor White
    Write-Host "  Group Policy Objects: $($statistics.GroupPolicyObjects)" -ForegroundColor White
    Write-Host "  Domain Trusts: $($statistics.DomainTrusts)" -ForegroundColor White
    Write-Host "`nFiles Created:" -ForegroundColor Cyan
    Get-ChildItem -Path $OutputPath -Filter "*.csv" | ForEach-Object {
        $size = [math]::Round($_.Length / 1KB, 2)
        Write-Host "  - $($_.Name) ($size KB)" -ForegroundColor White
    }
    Write-Host "================================`n" -ForegroundColor Cyan
}

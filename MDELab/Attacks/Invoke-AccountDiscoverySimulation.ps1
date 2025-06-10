param(
    [string]$OutputPath = "$env:TEMP\Discovery",
    [switch]$IncludeDomain,
    [Switch]$CleanUp
)


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

    if($IncludeDomain) {
        $DomainPath = "$OutputPath\Domain"
        if(-not (Test-Path -Path $DomainPath)) {
            New-Item -Path $OutputPath -ItemType Directory -ErrorAction SilentlyContinue
        }

        Get-ADUser -Filter * -Propery DisplayName, Enabled, SamAccountName | Format-Table -Property DisplayName, SamAccountName, Name | Out-File -FilePath "$DomainPath\domain_users.txt" -Encoding utf8

        # Fetch membership of "Domain Admins" and "Enterprise Admins"
        Get-ADGroupMember -Identity "Domain Admins" | Format-Table -Property SamAccountName, Name | Out-File -FilePath "$DomainPath\domain_admins.txt" -Encoding utf8
        Get-ADGroupMember -Identity "Enterprise Admins" | Format-Table -Property SamAccountName, Name | Out-File -FilePath "$DomainPath\enterprise_admins.txt" -Encoding utf8

    }
}
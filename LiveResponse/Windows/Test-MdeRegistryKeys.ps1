$regValues = @{
    "DisableAntiSpyware" = "HKLM:\\Software\\Policies\\Microsoft\\Windows Defender"
    "DpaDisabled" = "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows Defender\\Real-Time Protection"
    "DisableRealtimeMonitoring" = "HKLM:\\Software\\Policies\\Microsoft\\Windows Defender\\Real-Time Protection"
    "DisableBehaviorMonitoring" = "HKLM:\\Software\\Policies\\Microsoft\\Windows Defender\\Real-Time Protection"
    "DisableOnAccessProtection" = "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows Defender\\Real-Time Protection"
    "DisableScanOnRealtimeEnable" = "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows Defender\\Real-Time Protection"
    "ForceDefenderPassiveMode" = "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows Advanced Threat Protection"
}

function Get-RegistryValue {
    param (
        [string]$RegKeyPath,
        [string]$RegKeyName
    )

    $r = Get-ItemProperty -Path $RegKeyPath -Name $RegKeyName -ErrorAction SilentlyContinue
    return $r
}

$regValues.GetEnumerator() | ForEach-Object {
    $name = $_.Key
    $path = $_.Value
    

    $result = Get-RegistryValue -RegKeyPath $path -RegKeyName $name
    $result_text = "is not set"
    if($result -ne $null) {
        $result_text = "is set to $result"
    }
    Write-Host "Testing $name at path $path $result_text."
}
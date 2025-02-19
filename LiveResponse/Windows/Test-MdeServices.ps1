$services = @{
    "Defender AV" = "WinDefend"
    "DefenderEDR" = "Sense"
    "WinSecurityService" = "SecurityHealthService"
}

$services.GetEnumerator() | ForEach-Object {
    $name = $_.Key
    $path = $_.Value

    $result = Get-Service -Name $path -ErrorAction SilentlyContinue
    Write-Host "$name StartType: $($result.StartType) Current State: $($result.Status)"
}
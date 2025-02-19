$services = @{
    "eDLP" = "MDDlpSvc"
}

$services.GetEnumerator() | ForEach-Object {
    $name = $_.Key
    $path = $_.Value

    Write-Host "Attempting to starting service $name"
    Stop-Service -Name $path
    Start-Sleep -Seconds 5

    $result = Get-Service -Name $path -ErrorAction SilentlyContinue
    Write-Host "$name Current State: $($result.Status)"
}
param(
    [string]$Username = "",
    [string]$Path = "c:\temp"
)

$DateStr = (Get-Date).ToString("yyyMMdd")
$filePath = "$Path\GpResult-$DateStr.html"

if($Username -eq "") {
    Write-Host "Generating GPResult for COMPUTER"
    gpresult.exe /SCOPE COMPUTER /H "$filePath" /F
}
else {
    Write-Host "Generating GPResult for USER $Username"
    gpresult.exe /SCOPE USER /USER $Username /H "$filePath"
}

Write-Host "GPResult written to $filePath"
Param(
    [Parameter(Mandatory = $false)][string]$DSCModulesPath = ".\DSC\",
    [Parameter(Mandatory = $false)][string]$DSCZipFile = ".\DSC\IDAMLab_DSC.zip",
    [Parameter(Mandatory = $false)][string[]]$DSCModules = @("xActiveDirectory"),
    [Switch]$ForceDSCDownloads
)

foreach ($dscMod in $DSCModules) {
    if ($(test-path $($DSCModulesPath + $dscMod)) -eq $false) {
        Find-Module -Name $dscMod | Save-Module -Path $DSCModulesPath
    }
    else {
        Write-Output "The $dscMod folder already exists"
        if ($ForceDSCDownloads) {
            Find-Module -Name $dscMod | Save-Module -Path $DSCModulesPath -Force
        }
    }
}

Compress-Archive -Path $($DSCModulesPath + "*") $DSCZipFile -Force
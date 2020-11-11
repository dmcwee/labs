Param(
    [Parameter(Mandatory = $true)][string]$ResourceGroupName, 
    [Parameter(Mandatory = $true)][string]$ResourceGroupLocation,
    [Parameter(Mandatory = $false)][string[]]$DSCModules = @("xActiveDirectory"),
    [string]$ParametersFile = "azuredeploy.parameters.json",
    [Switch]$ForceDSCDownloads
)

foreach ($dscMod in $DSCModules) {
    if ($(test-path $(".\DSC\" + $dscMod)) -eq $false) {
        Find-Module -Name $dscMod | Save-Module -Path .\DSC\.
    }
    else {
        Write-Output "The $dscMod folder already exists"
        if ($ForceDSCDownloads) {
            Find-Module -Name $dscMod | Save-Module -Path .\DSC\. -Force
        }
    }
}

$dscFile = "IDAMLab_DSC.zip"
$dscFileOutput = ".\" + $dscFile

Compress-Archive -Path .\DSC\* $dscFileOutput -Force

New-AzResourceGroup -Name $ResourceGroupName -Location $ResourceGroupLocation

$storageAccountName = "idam" + $(get-date -format MMddyyyyHHmmss)

$storageAccount = New-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $storageAccountName -SkuName Standard_LRS -Location $ResourceGroupLocation

$ctx = $storageAccount.Context

$containerName = "dsc"
New-AzStorageContainer -Name $containerName -Context $ctx -Permission Blob
Write-Output "New-AzStorageContainer $storageAccountName and container $containerName has been created."

Set-AzStorageBlobContent -File $dscFileOutput -Container $containerName -Blob $dscFile -Context $ctx
Write-Output "$dscFile uploaded to the storage blob"

$sb = (Get-AzStorageBlob -Context $ctx -Blob $dscFile -Container $containerName).ICloudBlob.uri.absoluteuri
Write-Output "Storage Block URI: $sb"

$deploymentName = $ResourceGroupName + "_" + $(get-date -format MMddyyyy) + "_deployment"
Write-Output "Deploying $deploymentName"

New-AzResourceGroupDeployment -Name $deploymentName -ResourceGroupName $ResourceGroupName -TemplateFile ".\azuredeploy.json" -TemplateParameterFile $ParametersFile -DSCLocation $sb

Remove-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $storageAccountName -Force
Write-Output "Storage Account $storageAccountName has been removed."
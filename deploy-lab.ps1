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

#create the Root and Child certificates for the gateway
$rootCertName = $ResourceGroupName + "_rootcert"
$childCertName = $ResourceGroupName + "_childcert"
$cert = New-SelfSignedCertificate -Type Custom -KeySpec Signature `
-Subject "CN=$rootCertName" -KeyExportPolicy Exportable `
-HashAlgorithm sha256 -KeyLength 2048 `
-CertStoreLocation "Cert:\CurrentUser\My" -KeyUsageProperty Sign -KeyUsage CertSign
Write-Output "Root Cert $($cert.Subject) was created successfully for use with Point-to-Site VPN Gateway"

$childCert = New-SelfSignedCertificate -Type Custom -DnsName P2SChildCert -KeySpec Signature `
-Subject "CN=$childCertName" -KeyExportPolicy Exportable `
-HashAlgorithm sha256 -KeyLength 2048 `
-CertStoreLocation "Cert:\CurrentUser\My" `
-Signer $cert -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.2")
Write-Output "Child Cert $($childCert.Subject) was created successfully for authentication to Point-to-Site VPN Gateway"

$deploymentName = $ResourceGroupName + "_" + $(get-date -format MMddyyyy) + "_deployment"
Write-Output "Deploying $deploymentName"

$certString = [convert]::ToBase64String($cert.RawData)
Write-Output "Root Cert base-64 dump: $certString"

New-AzResourceGroupDeployment -Name $deploymentName -ResourceGroupName $ResourceGroupName `
-TemplateFile ".\azuredeploy.json" -TemplateParameterFile $ParametersFile -DSCLocation $sb `
-gatewayRootCertName $rootCertName -gatewayRootCert $certString

#Remove-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $storageAccountName -Force
#Write-Output "Storage Account $storageAccountName has been removed."
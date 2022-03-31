Param(
    [string]$RootCertCN = "P2SRootCert", 
    [string]$ChildCertCN = "P2SChildCert",
    [string]$CertOutputFile = "rootcert.txt"
)

$cert = New-SelfSignedCertificate -Type Custom -KeySpec Signature `
-Subject "CN=$RootCertCN" -KeyExportPolicy Exportable `
-HashAlgorithm sha256 -KeyLength 2048 `
-CertStoreLocation "Cert:\CurrentUser\My" -KeyUsageProperty Sign -KeyUsage CertSign

New-SelfSignedCertificate -Type Custom -DnsName P2SChildCert -KeySpec Signature `
-Subject "CN=$ChildCertCN" -KeyExportPolicy Exportable `
-HashAlgorithm sha256 -KeyLength 2048 `
-CertStoreLocation "Cert:\CurrentUser\My" `
-Signer $cert -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.2")

$certString = [convert]::ToBase64String($cert.RawData)
Write-Output "Root Cert String for Gateway: "
Write-Output $certString

$certString | Out-File -FilePath $CertOutputFile -Force

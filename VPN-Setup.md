# VPN Set-Up
To support the Point-to-Site VPN a root and child certificate is needed for authentication. Use the following steps to generate the certificate.

**Note:** The script is unsigned so you will need to run this in an environment that allows for unsigned script execution.

1. Download the [New-P2SCertificate.ps1](./common/scripts/New-P2SCertificate.ps1) script to your machine
1. Run:
```
PS> New-P2SCertificate.ps1 [optional: -RootCertCN myrootcert] [optional: -ChildCertCN mychildcert] [optional: -CertOutputFile pubrootcert.txt]
```
1. Copy the output in the terminal, or the output in the txt file generated and provide this as the *gatewayRootCert* parameter in the lab provisioning process or in the Gateway's Settings (post provisioning).
1. After the Root Certificate has been applied to the gateway's configuration go to the *Point-to-Site Configuration* and choose *Download VPN client*
1. Extract the file from the downloaded Zip and install the appropriate VPN agent (typically WindowsAmd64)
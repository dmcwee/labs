@minLength(3)
param username string
@secure()
param password string
@minLength(0)
param certificatedata string
@minLength(0)
param certificatename string
@minLength(3)
param domainName string = 'mcweeinc.com'
@minLength(3)
param domainNetbiosName string = 'mcwee'
param size string = 'Standard_B1ms'

var adServerName = 'LabAd'
var labServers = [
  {
    name:'Win2016'
    sku:'2016-Datacenter'
    offer: 'WindowsServer'
    publisher: 'MicrosoftWindowsServer'
    type: 'Windows'
    size: size
    ip: ''
  }
  {
    name:'Win2022'
    sku:'2022-Datacenter'
    offer: 'WindowsServer'
    publisher: 'MicrosoftWindowsServer'
    type: 'Windows'
    size: size
    ip: ''
  }
  {
    name:'LinuxUbuntu'
    publisher:'canonical'
    offer:'0001-com-ubuntu-server-jammy'
    sku:'22_04-lts-gen2'
    type: 'Linux'
    size: size
    ip: ''
  }
  {
    name:'WinClient11'
    publisher:'microsoftwindowsdesktop'
    offer: 'windows-11'
    sku:'win11-23h2-ent'
    type: 'Windows'
    size: 'Standard_B2ms'
    ip: ''
  }
]

module network '../Common/modules/network.bicep' = {
  params: {
    dns: ['10.0.2.5', '168.63.129.16']
    gatewayCertData: certificatedata
    gatewayCertName: certificatename
  }
}

module dcModule '../Common/modules/virtualMachine.bicep' = {
  params: {
    name: adServerName
    sku:'2016-Datacenter'
    offer: 'WindowsServer'
    publisher: 'MicrosoftWindowsServer'
    osType: 'Windows'
    size: 'Standard_B2ms'
    privateIp: '10.0.2.5'
    password: password
    username: username
    subnetId: network.outputs.clientSubnetId
    storageType: 'Standard_LRS'
  }
}

module servers '../Common/modules/virtualMachine.bicep' = [for (server, i) in labServers: {
  params: {
    name: server.name
    osType: server.type
    publisher: server.publisher
    offer: server.offer
    sku: server.sku
    size: (!empty(server.size))? server.size : size
    password: password
    username: username
    subnetId: network.outputs.clientSubnetId
    privateIp: (!empty(server.ip))? server.ip : '10.0.2.${i+50}'
    storageType: 'Standard_LRS'
  }
}]

resource dc 'Microsoft.Compute/virtualMachines@2024-11-01' existing = {
  name: adServerName
  dependsOn: [
    dcModule
  ]
}

resource adSetupCommand 'Microsoft.Compute/virtualMachines/extensions@2024-11-01' = {
  name: '${adServerName}-customscriptextension'
  location: resourceGroup().location
  parent: dc
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    settings: {

    }
    protectedSettings: {
      commandToExecute: 'powershell -executionpolicy bypass -File .\\DcSetup.ps1 -DomainName "${domainName}" -NetBiosName "${domainNetbiosName}" -Password ${password} -HydrationScript DcHydrate.ps1'
      fileUris: [
        'https://raw.githubusercontent.com/dmcwee/labs/refs/heads/dev/Common/DSC/DcSetup.ps1'
        'https://raw.githubusercontent.com/dmcwee/labs/refs/heads/dev/Common/DSC/DcHydrate.ps1'
      ]
    }
  }
}

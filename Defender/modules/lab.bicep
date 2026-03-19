@minLength(3)
param username string = 'cmadmin'
@secure()
param password string
@minLength(0)
param gatewayCertData string
@minLength(0)
param gatewayCertName string
@minLength(3)
param domainName string = 'mcweeinc.com'
@minLength(3)
param domainNetbiosName string = 'mcwee'
@minLength(3)
param subDomain string = 'tech.mcweeinc.com'
@minLength(3)
param subDomainNetbiosName string = 'tech'
@minLength(1)
param size string = 'Standard_B2ms'
@minLength(1)
param setupFilePaths string = 'https://raw.githubusercontent.com/dmcwee/labs/refs/heads/published/pub/DSC'

var labServers = [
  {
    name:'Win2016'
    sku:'2016-Datacenter'
    offer: 'WindowsServer'
    publisher: 'MicrosoftWindowsServer'
    type: 'Windows'
    size: size
  }
  {
    name:'Win2022'
    sku:'2022-Datacenter'
    offer: 'WindowsServer'
    publisher: 'MicrosoftWindowsServer'
    type: 'Windows'
    size: size
  }
  {
    name:'LinuxUbuntu'
    publisher:'canonical'
    offer:'0001-com-ubuntu-server-jammy'
    sku:'22_04-lts-gen2'
    type: 'Linux'
    size: size
  }
]

module network '../../Common/modules/network.bicep' = {
  params: {
    dns: ['10.0.2.5', '168.63.129.16']
    gatewayCertData: gatewayCertData
    gatewayCertName: gatewayCertName
  }
}

module labad '../../Common/modules/virtualMachine.bicep' = {
  params: {
    name: 'LabAd'
    sku:'2022-Datacenter'
    offer: 'WindowsServer'
    publisher: 'MicrosoftWindowsServer'
    osType: 'Windows'
    size: size
    privateIp: '10.0.2.5'
    password: password
    username: username
    subnetId: network.outputs.clientSubnetId
    storageType: 'Standard_LRS'
  }
}

module labsubad '../../Common/modules/virtualMachine.bicep' = {
  params: {
    name: 'LabSubAd'
    sku:'2022-Datacenter'
    offer: 'WindowsServer'
    publisher: 'MicrosoftWindowsServer'
    osType: 'Windows'
    size: size
    privateIp: '10.0.2.6'
    password: password
    username: username
    subnetId: network.outputs.clientSubnetId
    storageType: 'Standard_LRS'
  }
}

module client '../../Common/modules/virtualMachine.bicep' = {
  params: {
    name: 'WinClient11'
    osType: 'Windows'
    publisher: 'microsoftwindowsdesktop'
    offer: 'windows-11'
    sku: 'win11-23h2-ent'
    size: size
    password: password
    username: username
    subnetId: network.outputs.clientSubnetId
    privateIp: '10.0.2.40'
    storageType: 'Standard_LRS'
  }
}

module servers '../../Common/modules/virtualMachine.bicep' = [for (server, i) in labServers: {
  params: {
    name: server.name
    osType: server.type
    publisher: server.publisher
    offer: server.offer
    sku: server.sku
    size: size
    password: password
    username: username
    subnetId: network.outputs.clientSubnetId
    privateIp: '10.0.2.${i+50}'
    storageType: 'Standard_LRS'
  }
}]

resource dc1 'Microsoft.Compute/virtualMachines@2024-11-01' existing = {
  name: 'LabAd'
  dependsOn: [
    labad
  ]
}

resource dc2 'Microsoft.Compute/virtualMachines@2024-11-01' existing = {
  name: 'LabSubAd'
  dependsOn: [
    labsubad
  ]
}

resource badClient 'Microsoft.Compute/virtualMachines@2024-11-01' existing = {
  name: 'WinClient11'
  dependsOn: [
    client
  ]
}

resource badClientSetup 'Microsoft.Compute/virtualMachines/extensions@2024-11-01' = {
  name: 'WinClient11-customscriptextension'
  location: resourceGroup().location
  parent: badClient
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    settings: {

    }
    protectedSettings: {
      commandToExecute: 'powershell -executionpolicy bypass -command "New-Item -Path c:\\hydration -ItemType Directory -Force; Copy-Item -Path .\\*.ps1 -Destination c:\\hydration\\ -Force"'
      fileUris: [
        '${setupFilePaths}/run-victimpc.ps1'
      ]
    }
  }
}

resource adDomainSetup 'Microsoft.Compute/virtualMachines/extensions@2024-11-01' = {
  name: 'LabAd-customscriptextension'
  location: resourceGroup().location
  parent: dc1
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
        '${setupFilePaths}/DcSetup.ps1'
        '${setupFilePaths}/DcHydrate.ps1'
      ]
    }
  }
}

resource adSubdomainSetup 'Microsoft.Compute/virtualMachines/extensions@2024-11-01' = {
  name: 'LabSubAd-customscriptextension'
  location: resourceGroup().location
  parent: dc2
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    settings: {

    }
    protectedSettings: {
      commandToExecute: 'powershell -executionpolicy bypass -File .\\DcSetup.ps1 -DomainName "${subDomain}" -NetBiosName "${subDomainNetbiosName}" -Password ${password} -HydrationScript DcHydrate.ps1'
      fileUris: [
        '${setupFilePaths}/DcSetup.ps1'
        '${setupFilePaths}/DcHydrate.ps1'
      ]
    }
  }
}


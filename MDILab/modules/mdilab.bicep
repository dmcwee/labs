@minLength(3)
param username string
@secure()
param password string
@minLength(0)
param gatewayCertData string
@minLength(0)
param gatewayCertName string
@minLength(3)
param subDomain1 string = 'mayor.mcweeinc.com'
@minLength(3)
param subDomain2 string = 'tech.mcweeinc.com'
@minLength(3)
param netbiosName1 string = 'mayor'
@minLength(3)
param netbiosName2 string = 'tech'
param size string = 'Standard_B1ms'

module network '../../Common/modules/network.bicep' = {
  params: {
    dns: ['10.0.2.15', '168.63.129.16']
    gatewayCertData: gatewayCertData
    gatewayCertName: gatewayCertName
  }
}

module dcModule1 '../../Common/modules/virtualMachine.bicep' = {
  params: {
    name: 'LabSubAd1'
    sku:'2022-Datacenter'
    offer: 'WindowsServer'
    publisher: 'MicrosoftWindowsServer'
    osType: 'Windows'
    size: 'Standard_B2ms'
    privateIp: '10.0.2.15'
    password: password
    username: username
    subnetId: network.outputs.clientSubnetId
    storageType: 'Standard_LRS'
  }
}

module dcModule2 '../../Common/modules/virtualMachine.bicep' = {
  params: {
    name: 'LabSubAd2'
    sku:'2022-Datacenter'
    offer: 'WindowsServer'
    publisher: 'MicrosoftWindowsServer'
    osType: 'Windows'
    size: 'Standard_B2ms'
    privateIp: '10.0.2.16'
    password: password
    username: username
    subnetId: network.outputs.clientSubnetId
    storageType: 'Standard_LRS'
  }
}

resource dc1 'Microsoft.Compute/virtualMachines@2024-11-01' existing = {
  name: 'LabSubAd1'
  dependsOn: [
    dcModule1
  ]
}

resource dc2 'Microsoft.Compute/virtualMachines@2024-11-01' existing = {
  name: 'LabSubAd2'
  dependsOn: [
    dcModule2
  ]
}

resource adSetupCommand1 'Microsoft.Compute/virtualMachines/extensions@2024-11-01' = {
  name: 'LabSubAd1-customscriptextension'
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
      commandToExecute: 'powershell -executionpolicy bypass -File .\\DcSetup.ps1 -DomainName "${subDomain1}" -NetBiosName "${netbiosName1}" -Password ${password} -HydrationScript DcHydrate.ps1'
      fileUris: [
        'https://raw.githubusercontent.com/dmcwee/labs/refs/heads/dev/Common/DSC/DcSetup.ps1'
        'https://raw.githubusercontent.com/dmcwee/labs/refs/heads/dev/Common/DSC/DcHydrate.ps1'
      ]
    }
  }
}

resource adSetupCommand2 'Microsoft.Compute/virtualMachines/extensions@2024-11-01' = {
  name: 'LabSubAd2-customscriptextension'
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
      commandToExecute: 'powershell -executionpolicy bypass -File .\\DcSetup.ps1 -DomainName "${subDomain2}" -NetBiosName "${netbiosName2}" -Password ${password} -HydrationScript DcHydrate.ps1'
      fileUris: [
        'https://raw.githubusercontent.com/dmcwee/labs/refs/heads/dev/Common/DSC/DcSetup.ps1'
        'https://raw.githubusercontent.com/dmcwee/labs/refs/heads/dev/Common/DSC/DcHydrate.ps1'
      ]
    }
  }
}


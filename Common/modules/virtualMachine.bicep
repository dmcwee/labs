param subnetId string
param privateIp string
param storageType string
param username string
@secure()
param password string
param requirePlan bool = false

param location string = resourceGroup().location
param name string = 'Server2016'
param size string = 'Standard_B4ms'
param publisher string = 'MicrosoftWindowsServer'
param offer string = 'WindowsServer'
param sku string = '2016-Datacenter'
param version string = 'latest'
@allowed(['Linux','Windows'])
param osType string = 'Windows'

resource networkInterface 'Microsoft.Network/networkInterfaces@2024-05-01' = {
  name: '${name}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnetId
          }
          privateIPAllocationMethod: 'Static'
          privateIPAddress: privateIp
        }
      }
    ]
  }
}

resource serverVm 'Microsoft.Compute/virtualMachines@2024-11-01' = {
  name: name
  location: location
  properties: {
    hardwareProfile: {vmSize: size}
    osProfile: (osType == 'Linux') ? {
      adminPassword: password
      adminUsername: username
      computerName: name
      allowExtensionOperations: true
      linuxConfiguration: {
        disablePasswordAuthentication: false
        provisionVMAgent: true
        patchSettings: {
          patchMode: 'ImageDefault'
          assessmentMode: 'ImageDefault'
        }
      }
    } : {
      adminPassword: password
      adminUsername: username
      computerName: name
      allowExtensionOperations: true
    }
    storageProfile: {
      imageReference: {
        publisher: publisher
        offer: offer
        sku: sku
        version: version
      }
      osDisk: {
        name: '${name}-osdisk'
        createOption: 'FromImage'
        managedDisk: { storageAccountType: storageType }
        osType: osType
      }
    }
    networkProfile: {
      networkInterfaces: [
        { id: networkInterface.id }
      ]
    }
    diagnosticsProfile: (osType == 'Linux') ? {
      bootDiagnostics: {
        enabled: true
      }
    } : {}
  }
  plan: (requirePlan) ? {
    name: sku
    publisher: publisher
    product: offer
  }: null
}

module schedule 'schedule.bicep' = {
  params: {
    name: name
    id: serverVm.id
  }
}

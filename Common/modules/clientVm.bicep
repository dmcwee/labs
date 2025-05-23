param subnetId string
param privateIp string
param storageType string
param username string
@secure()
param password string

param location string = resourceGroup().location
param name string = 'Client'
param size string = 'Standard_B4ms'
param publisher string = 'microsoftwindowsdesktop'
param offer string = 'windows-10'
param sku string = 'win10-22h2-ent'

resource networkInterface 'Microsoft.Network/networkInterfaces@2021-02-01' = {
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

resource client 'Microsoft.Compute/virtualMachines@2024-11-01' = {
  location: location
  name: name
  properties: {
    hardwareProfile: { vmSize: size }
    osProfile: {
      adminUsername: username
      adminPassword: password
      computerName: name
    }
    storageProfile: {
      imageReference: {
        publisher: publisher
        offer: offer
        sku: sku
        version: 'latest'
      }
      osDisk: {
        name: '${name}-osdisk'
        createOption: 'FromImage'
        managedDisk: {storageAccountType: storageType}
      }
    }
    networkProfile: {
      networkInterfaces: [
        {id: networkInterface.id}
      ]
    }
  }  
}

module schedule 'schedule.bicep' = {
  params: {
    id: client.id
    name: name
  }
}

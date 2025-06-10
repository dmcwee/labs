@minLength(3)
param username string
@secure()
param password string
@minLength(0)
param certificatedata string
@minLength(0)
param certificatename string

module network '../modules/network.bicep' = {
  params: {
    gatewayCertData: certificatedata
    gatewayCertName: certificatename
  }
}

module server '../modules/virtualMachine.bicep' = {
  params: {
    name: 'Windows2016'
    osType: 'Windows'
    publisher: 'MicrosoftWindowsServer'
    offer: 'WindowsServer'
    sku: '2016-Datacenter'
    size: 'Standard_B1ms'
    password: password
    username: username
    subnetId: network.outputs.clientSubnetId
    privateIp: '10.0.2.100'
    storageType: 'Standard_LRS'
  }
}

module linux '../modules/virtualMachine.bicep' = {
  params: {
    name: 'UbuntuLinux'
    osType: 'Linux'
    publisher: 'canonical'
    offer: '0001-com-ubuntu-server-jammy'
    sku: '22_04-lts-gen2'
    size: 'Standard_B1ms'
    password: password
    username: username
    subnetId: network.outputs.clientSubnetId
    privateIp: '10.0.2.101'
    storageType: 'Standard_LRS'
  }
}

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

module client '../modules/virtualMachine.bicep' = {
  params: {
    name: 'Win11Client'
    subnetId: network.outputs.clientSubnetId
    privateIp: '10.0.2.100'
    storageType: 'Standard_LRS'
    password: password
    username: username
    publisher:'microsoftwindowsdesktop'
    offer: 'windows-11'
    sku:'win11-23h2-ent'
    osType: 'Windows'
  }
}

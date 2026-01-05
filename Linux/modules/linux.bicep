@minLength(3)
param username string
@secure()
param password string
@minLength(0)
param gatewayCertData string
@minLength(0)
param gatewayCertName string
param size string = 'Standard_B1ms'

var linuxServers = [
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
    name:'LinuxSuseOs1'
    publisher:'suse'
    offer:'sles-12-sp5-basic'
    sku:'gen2'
    type: 'Linux'
    size: size
    ip: ''
  }
]

module network '../../Common/modules/network.bicep' = {
  params: {
    dns: ['168.63.129.16']
    gatewayCertData: gatewayCertData
    gatewayCertName: gatewayCertName
  }
}

module servers '../../Common/modules/virtualMachine.bicep' = [for (server, i) in linuxServers: {
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

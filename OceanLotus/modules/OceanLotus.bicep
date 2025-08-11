@secure()
param password string
param username string
param gatewayCertData string
param gatewayCertName string
param size string = 'Standard_B1ms'

var labServers = [
  {
    name: 'vhagar'
    ip: '10.90.30.20'
    sku: '2019-DataCenter'
    offer: 'WindowsServer'
    publisher: 'MicrosoftWindowsServer'
    osType: 'Windows'
    requirePlan: false
    tags: {
      ExcludeMdeAutoProvisioning: 'True'
    }
  }
  {
    name: 'drogon'
    ip: '10.90.30.7'
    publisher:'canonical'
    offer:'0001-com-ubuntu-server-jammy'
    sku:'22_04-lts-gen2'
    osType: 'Linux'
    requirePlan: false
    tags: {
      ExcludeMdeAutoProvisioning: 'True'
    }
  }
  {
    name: 'kali'
    ip: '10.90.30.26'
    publisher: 'kali-linux'
    offer: 'kali'
    sku: 'kali-2024-4'
    osType: 'Linux'
    requirePlan: true
    plan: {
      name: 'kali-2024-4'
      publisher: 'kali-linux'
      product: 'kali'
    }
    tags: {
      ExcludeMdeAutoProvisioning: 'True'
    }
  }
]

module network '../../Common/modules/network.bicep' = {
  params: {
    gatewayCertData: gatewayCertData
    gatewayCertName: gatewayCertName
    range: '10.90.0.0/16'
    clientRange: '10.90.30.0/24'
    gatewayRange: '10.90.100.0/24'
    gatewayClientRange: '10.10.10.0/24'
    vpnClientProtocol: ['IkeV2']
    gatewaySku: 'VpnGw1'
  }
}

module servers '../../Common/modules/virtualMachine.bicep' = [for (server, i) in labServers: {
  params: {
    name: server.name
    osType: server.osType
    publisher: server.publisher
    offer: server.offer
    sku: server.sku
    size: size
    password: password
    username: username
    subnetId: network.outputs.clientSubnetId
    privateIp: (!empty(server.ip))? server.ip : '10.50.30.${i+50}'
    storageType: 'Standard_LRS'
    requirePlan: server.requirePlan
    tags: server.tags
  }
}]

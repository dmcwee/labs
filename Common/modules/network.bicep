param name string = '${toLower(resourceGroup().name)}-network'
param range string = '10.0.0.0/16'
param clientRange string = '10.0.2.0/24'
param gatewayRange string = '10.0.100.0/24'
param dns array = ['168.63.129.16']
param location string = resourceGroup().location

resource network 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: name
  location: location
  properties: {
    addressSpace: {addressPrefixes: [ range ]}
    subnets: [
      {
        name: 'GatewaySubnet'
        properties: { 
          addressPrefix: gatewayRange 
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: 'client-subnet'
        properties: {addressPrefix: clientRange}
      }
    ]
    dhcpOptions: {dnsServers: dns}
  }
}

output gatewaySubnetId string = network.properties.subnets[0].id
output clientSubnetId string = network.properties.subnets[1].id

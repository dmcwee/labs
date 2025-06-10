param name string = '${toLower(resourceGroup().name)}-network'
param gatewayName string = 'gateway-${uniqueString(resourceGroup().id)}'
param gatewayCertName string = ''
param gatewayCertData string = ''
param range string = '10.0.0.0/16'
param clientRange string = '10.0.2.0/24'
param gatewayRange string = '10.0.100.0/24'
param gatewayClientRange string = '10.10.10.0/24'
param dns array = ['168.63.129.16']
param location string = resourceGroup().location
param gatewaySku string = 'Basic'
param gatewayVpnType string = 'RouteBased'
param gatewayGeneration string = 'Generation1'
param gatewayType string = 'Vpn'

resource network 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: name
  location: location
  properties: {
    addressSpace: {addressPrefixes: [ range ]}
    dhcpOptions: {dnsServers: dns}
  }
}

resource gatewaySubnet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' = {
  name: 'GatewaySubnet'
  parent: network
  properties: { 
    addressPrefix: gatewayRange 
    privateEndpointNetworkPolicies: 'Enabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
  }
}

resource clientSubnet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' = {
  name: 'client-subnet'
  parent: network
  properties: {addressPrefix: clientRange}
}

resource publicIp 'Microsoft.Network/publicIPAddresses@2024-05-01' = {
  name: '${gatewayName}-pub-ip'
  location: location
  sku: {
    name: 'Basic'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    idleTimeoutInMinutes: 4
    dnsSettings: {
      domainNameLabel: toLower(gatewayName)
    }
  }
}

resource gateway 'Microsoft.Network/virtualNetworkGateways@2024-05-01' = {
  name: name
  location: location
  properties: {
    enablePrivateIpAddress: false
    ipConfigurations: [
      {
        name: 'default'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: gatewaySubnet.id
          }
          publicIPAddress: {id: publicIp.id }
        }
      }
    ]
    vpnGatewayGeneration: gatewayGeneration
    sku: {
      name: gatewaySku
      tier: gatewaySku
    }
    gatewayType: gatewayType
    vpnType: gatewayVpnType
    enableBgp: false
    activeActive:false
    vpnClientConfiguration: {
      vpnClientAddressPool: {addressPrefixes: [gatewayClientRange] }
      vpnClientProtocols: ['SSTP']
      vpnAuthenticationTypes: ['Certificate']
      vpnClientRootCertificates: (!empty(gatewayCertName) && !empty(gatewayCertData)) ? [
        {
          name: gatewayCertName
          properties: {
            publicCertData: gatewayCertData
          }
        }
      ] : []
    }
  }
}

output gatewaySubnetId string = gatewaySubnet.id
output clientSubnetId string = clientSubnet.id

@minLength(0)
param certName string
@minLength(0)
param certData string
param subnetId string

param name string = '${resourceGroup().name}-gateway'
param location string = resourceGroup().location
param sku string = 'Basic'
param vpnType string = 'RouteBased'
param generation string = 'Generation1'
param gatewayType string = 'Vpn'

var gatewayName = 'gateway-${uniqueString(resourceGroup().id)}'
var clientRange = '10.10.10.0/24'
var clientCert = (!empty(certName) && !empty(certData)) ? [
  {
    name: certName
    properties: {
      publicCertData: certData
    }
  }
] : []


resource publicIp 'Microsoft.Network/publicIPAddresses@2024-05-01' = {
  name: '${name}-pub-ip'
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
            id: subnetId
          }
          publicIPAddress: {id: publicIp.id }
        }
      }
    ]
    vpnGatewayGeneration: generation
    sku: {
      name: sku
      tier: sku
    }
    gatewayType: gatewayType
    vpnType: vpnType
    enableBgp: false
    activeActive:false
    vpnClientConfiguration: {
      vpnClientAddressPool: {addressPrefixes: [clientRange] }
      vpnClientProtocols: ['SSTP']
      vpnAuthenticationTypes: ['Certificate']
      vpnClientRootCertificates: clientCert
    }
  }
}

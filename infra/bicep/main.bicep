// Landing zone for the SmartHotel lift-and-shift.
// Mirrors the on-premises flat network so VM IP addresses (and therefore app
// configuration) do not have to change after migration.
//
// Deploy:  see scripts/azure/01-deploy-landing-zone.sh

targetScope = 'resourceGroup'

@description('Azure region.')
param location string = resourceGroup().location

@description('Address space of the VNet. Must contain the on-premises IPs you want to keep.')
param vnetAddressPrefix string = '192.168.0.0/16'

@description('Subnet that receives the migrated VMs (mirrors the on-prem LAN).')
param workloadSubnetPrefix string = '192.168.0.0/24'

@description('Subnet reserved for Azure Bastion (must be /26 or larger).')
param bastionSubnetPrefix string = '192.168.1.0/26'

@description('IP of UbuntuWAF (Nginx reverse proxy / WAF). Replace with your real on-prem IPs.')
param wafIp string = '192.168.0.8'

@description('IP of SmartHotelWeb1 (web tier).')
param web1Ip string = '192.168.0.4'

@description('IP of SmartHotelWeb2 (application tier).')
param web2Ip string = '192.168.0.5'

@description('IP of SmartHotelSQL1 (database tier).')
param sqlIp string = '192.168.0.6'

@description('Deploy Azure Bastion (Basic SKU, billed hourly). Needed for RDP/SSH because only the WAF has a public IP.')
param deployBastion bool = false

@description('Storage account that holds uploaded VHDs (manual migration path).')
param storageAccountName string = 'shvhd${uniqueString(resourceGroup().id)}'

var vnetName = 'vnet-smarthotel'
var workloadSubnetName = 'snet-onprem-mirror'
var nsgName = 'nsg-smarthotel'

resource nsg 'Microsoft.Network/networkSecurityGroups@2023-11-01' = {
  name: nsgName
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allow-Internet-to-WAF'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: 'Internet'
          sourcePortRange: '*'
          destinationAddressPrefix: wafIp
          destinationPortRanges: [ '80', '443' ]
        }
      }
      {
        name: 'Allow-Bastion-Admin'
        properties: {
          priority: 110
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: bastionSubnetPrefix
          sourcePortRange: '*'
          destinationAddressPrefix: workloadSubnetPrefix
          destinationPortRanges: [ '22', '3389' ]
        }
      }
      {
        name: 'Allow-WAF-to-Web1'
        properties: {
          priority: 130
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: wafIp
          sourcePortRange: '*'
          destinationAddressPrefix: web1Ip
          destinationPortRanges: [ '80', '443' ]
        }
      }
      {
        name: 'Allow-Web1-to-Web2'
        properties: {
          priority: 140
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: web1Ip
          sourcePortRange: '*'
          destinationAddressPrefix: web2Ip
          destinationPortRanges: [ '80', '443' ]
        }
      }
      {
        name: 'Allow-Web2-to-SQL'
        properties: {
          priority: 150
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: web2Ip
          sourcePortRange: '*'
          destinationAddressPrefix: sqlIp
          destinationPortRange: '1433'
        }
      }
      {
        name: 'Deny-Other-Intra-Subnet'
        properties: {
          priority: 4000
          direction: 'Inbound'
          access: 'Deny'
          protocol: '*'
          sourceAddressPrefix: workloadSubnetPrefix
          sourcePortRange: '*'
          destinationAddressPrefix: workloadSubnetPrefix
          destinationPortRange: '*'
        }
      }
    ]
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [ vnetAddressPrefix ]
    }
    subnets: [
      {
        name: workloadSubnetName
        properties: {
          addressPrefix: workloadSubnetPrefix
          networkSecurityGroup: {
            id: nsg.id
          }
        }
      }
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: bastionSubnetPrefix
        }
      }
    ]
  }
}

// Public IP for the WAF VM (the only internet-facing entry point).
resource wafPip 'Microsoft.Network/publicIPAddresses@2023-11-01' = {
  name: 'pip-waf'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource bastionPip 'Microsoft.Network/publicIPAddresses@2023-11-01' = if (deployBastion) {
  name: 'pip-bastion'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource bastion 'Microsoft.Network/bastionHosts@2023-11-01' = if (deployBastion) {
  name: 'bas-smarthotel'
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          subnet: {
            id: '${vnet.id}/subnets/AzureBastionSubnet'
          }
          publicIPAddress: {
            id: bastionPip.id
          }
        }
      }
    ]
  }
}

resource storage 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    supportsHttpsTrafficOnly: true
  }
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-01-01' = {
  parent: storage
  name: 'default'
}

resource vhdContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  parent: blobService
  name: 'vhds'
  properties: {
    publicAccess: 'None'
  }
}

output vnetName string = vnet.name
output workloadSubnetName string = workloadSubnetName
output storageAccountName string = storage.name
output wafPublicIpName string = wafPip.name
output wafPublicIpAddress string = wafPip.properties.ipAddress

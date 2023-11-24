targetScope = 'subscription'

param project string = 'acaresiliency'
param location string = deployment().location
param tags object = {}

@description('Optional. Workload profiles configured for the Managed Environment.')
param workloadProfiles array = [ 
{
    name: 'Consumption'
    workloadProfileType: 'Consumption'
  }    
]

// Variables
var projectName = project
var deploymentName = deployment().name
var resourceGroupName = 'rg-${projectName}'
var virtualNetworkName = 'vnet-${projectName}'
var natGatewayName = 'nat-${projectName}'
var logAnalyticsName = 'law-${projectName}'
var acaEnvironmentName = 'env-${projectName}'
var infrastructureResourceGroupName = '${resourceGroupName}_ME'

// Resource Group
module modResourceGroup 'CARML/resources/resource-group/main.bicep' = {
  name: take('${deploymentName}-rg', 58)
  params: {
    name: resourceGroupName
    location: location
    tags: tags
  }
}

// Log Analytics Workspace
module modLogAnalytics 'CARML/operational-insights/workspace/main.bicep' ={
  name: take('${deploymentName}-law', 58)
  scope : resourceGroup(resourceGroupName)
  params: {
    name: logAnalyticsName
    location:location
    tags: tags
  }
  dependsOn: [
    modResourceGroup
  ]
}

// Networking
module modNetworking 'modules/network.bicep' = {
  name: take('${deploymentName}-networking', 58)
  scope : resourceGroup(resourceGroupName)
  params: {
    virtualNetworkName: virtualNetworkName
    natGatewayName: natGatewayName
    natGatewayEnabled: true
    location: location
  }
  dependsOn: [
    modResourceGroup
  ]
}

// ACA environment
module modAcaEnvironment  'CARML/app/managed-environment/main.bicep' = {
  name: take('${deploymentName}-acaenv', 58)
  scope : resourceGroup(resourceGroupName)
  params: {
    name: acaEnvironmentName
    location: location
    tags: tags
    logAnalyticsWorkspaceResourceId: modLogAnalytics.outputs.resourceId
    enableDefaultTelemetry: false
    internal: false
    infrastructureResourceGroup : infrastructureResourceGroupName
    infrastructureSubnetId: modNetworking.outputs.firstSubnetId
    workloadProfiles: workloadProfiles
  }
  dependsOn: [ 
    modResourceGroup 
    modNetworking
    modLogAnalytics
  ]
}


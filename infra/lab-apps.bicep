targetScope = 'subscription'

param project string = 'acaresiliency'
param location string = deployment().location
param tags object = {}


// Variables
var projectName = project
var resourceGroupName = 'rg-${projectName}'
var acaEnvironmentName = 'env-${projectName}'

var generatorVer = '5.0.2'
var processorVer = '2.0.5'


resource managedEnvironment 'Microsoft.App/managedEnvironments@2023-05-01' existing = {
  name : acaEnvironmentName
  scope : resourceGroup(resourceGroupName)
}

module app01  'CARML/app/container-app/main.bicep' = {
  name: take('${deployment().name}-app01', 64)
  scope : resourceGroup(resourceGroupName)
  params: {
    name: 'app-generator'
    environmentId: managedEnvironment.id
    ingressAllowInsecure:true
    ingressExternal:true
    ingressTargetPort: 8080
    ingressTransport:'auto'
    containers: [
      {
        image: 'massimocrippa/aca-generator:${generatorVer}'
        name: 'app-generator'
        resources:{
          cpu: json('1')
          memory:'2Gi'
        }
        env: [
          {
            name: 'ASPNETCORE_ENVIRONMENT'
            value: 'Development'
          }
          {
            name: 'ASPNETCORE_URLS'
            value: 'http://+:8080'
          }
          {
            name: 'ACA_APP_Target_URL'
            value: 'http://app-processor'
          }
        ]
      }
    ]
    scaleMinReplicas :1
    scaleMaxReplicas: 1
    workloadProfileName: 'Consumption'
    location: location
    tags: tags
  }
}

module app02  'CARML/app/container-app/main.bicep' = {
  name: take('${deployment().name}-app02', 64)
  scope : resourceGroup(resourceGroupName)
  params: {
    name: 'app-processor'
    environmentId: managedEnvironment.id
    ingressAllowInsecure:true
    ingressExternal:true
    ingressTargetPort: 8080
    ingressTransport:'auto'
    containers: [
      {
        image: 'massimocrippa/aca-processor:${processorVer}'
        name: 'app-processor'
        resources:{
          cpu: json('1')
          memory:'2Gi'
        }
        env: [
          {
            name: 'ASPNETCORE_ENVIRONMENT'
            value: 'Development'
          }
          {
            name: 'ASPNETCORE_URLS'
            value: 'http://+:8080'
          }
        ]
      }
    ]
    scaleMinReplicas :1
    scaleMaxReplicas: 1
    workloadProfileName: 'Consumption'
    location: location
    tags: tags
  }
}


module appConsumption 'modules/resiliency.bicep' = {
  name: take('${deployment().name}-resiliency', 64)
  scope : resourceGroup(resourceGroupName)
  params: {
    appName : app02.outputs.name
  }
}

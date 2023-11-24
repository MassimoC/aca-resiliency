param id string
param targetProfile string = 'wp-${id}'
param environmentId string
param location string
param tags object
param replicas int = 1

var appName = 'app-${id}'

module app01  '../CARML/app/container-app/main.bicep' = {
  name: take('${deployment().name}-${appName}', 64)
  params: {
    name: appName
    environmentId: environmentId
    ingressAllowInsecure:true
    ingressExternal:true
    ingressTargetPort: 9898
    ingressTransport:'auto'
    containers: [
      {
        image: 'ghcr.io/stefanprodan/podinfo:latest'
        name: appName
        resources:{
          cpu: json('1')
          memory:'2Gi'
        }
      }
    ]
    scaleMinReplicas :replicas
    scaleMaxReplicas: replicas
    workloadProfileName: targetProfile
    location: location
    tags: tags
  }
}

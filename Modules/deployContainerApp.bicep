// This module deploys a Route Table

// Importing necessary types
import { regionType } from '.shared/commonTypes.bicep'

// Parameters for the deployments
param regionAbbreviation regionType
param projectName string
param CAEresourceId string


// Importing shared resources and configurations
var locations = loadJsonContent('.shared/locations.json')
var location = locations[regionAbbreviation].region
var deploymentName = 'DeployCA-${projectName}-${regionAbbreviation}'

// Naming conventions module
module naming '.shared/naming_conventions.bicep' = {
  name: 'naming'
  params: {
    projectName: projectName
    regionAbbreviation: regionAbbreviation
    subscriptionName: subscription().displayName
  }
}

module Container_App 'br/public:avm/res/app/container-app:0.18.1' = {
  name: deploymentName
  params: {
    name: naming.outputs.ContainerApp
    containers:  [
      {
        name: 'helloworldcontainer'
        image: 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'
        resources: {
          cpu: 4
          memory: '8Gi'
        }
      }
    ]
    environmentResourceId: CAEresourceId
    disableIngress: false
    ingressExternal: true
    ingressAllowInsecure: false
    ingressTransport: 'auto'
    location: location
    scaleSettings: {
      maxReplicas: 1
      minReplicas: 1
      cooldownPeriod: 300
      pollingInterval: 30
    }
    activeRevisionsMode: 'Single'
    maxInactiveRevisions: 100
    clientCertificateMode: 'ignore'
  }
}

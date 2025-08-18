
# Bicep Scripts Repository

This repository contains a collection of reusable [Bicep](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/overview) modules and shared resources designed to streamline Azure infrastructure deployments.

## 🔧 Structure

### 📁 Modules/

Modular Bicep scripts for deploying common Azure resources:

- `.shared/` – Shared resources used across modules
- `bicepconfig.json` – Microsoft Graph Extension
- `createEntraGroup.bicep` – Entra ID Group
- `deployACR.bicep` – Azure Container Registry
- `deployADF.bicep` – Azure Data Factory
- `deployAppInsights.bicep` – Applicatiın Insights
- `deployASP.bicep` – App Service Plan
- `deployDBW.bicep` – Data Bricks Workspace
- `deployFunctionApp.bicep` – Azure Function App
- `deployKeyVault.bicep` – Key Vault
- `deployLogAnalyticsWorkspace.bicep` – Log Analytics Workspace
- `deployManagedDevOpsPool.bicep` – Managed DevOps Pool
- `deployManagedIdentity.bicep` – User-Assigned Identity
- `deployNSG.bicep` – Network Security Group
- `deployRG.bicep` – Resource Group
- `deployRouteTable.bicep` – Route Table
- `deployStorageAccount.bicep` – Storage Account
- `deploySubnet.bicep` – Subnet
- `deployVM.bicep` – Virtual Machine
- `deployVnet.bicep` – Virtual Network
- `policyAssignment.bicep` – Policy Assignment
- `policyDefinition.bicep` – Policy Definition


### 📁 Modules/.shared/

Shared templates and JSON configurations:

- `commonTypes.bicep` – Shared type definitions
- `locations.json` – Supported Azure regions
- `MDP_OS.json` / `MDP_vmSKU.json` – VM image/SKU metadata for Managed DevOps Pools
- `naming_conventions.bicep` – Standard naming patterns
- `pe_services.json` – Private Endpoint supported services
- `privatednszones.json` – Private DNS zone configurations
- `VM_OS.json` / `vmSizes.json` – VM image/SKU metadata for Virtual Machines

## 🚀 Usage

Import individual modules into your main Bicep templates using the `module` keyword. Example:

```bicep
module storage 'Modules/deployStorageAccount.bicep' = {
  name: 'deployStorage'
  params: {
    ...
  }
}
```

Ensure shared definitions from `.shared/` are included where necessary.

## 📦 Prerequisites

- Azure CLI with Bicep installed: `az bicep install`
- Properly configured Azure subscription and permissions

## ✅ Status

This repo is actively maintained and used for deploying Azure workloads using modular, repeatable, and scalable infrastructure as code (IaC) practices.


## ✍️ Author

Maintained by [ozanberkpolat](https://github.com/ozanberkpolat)


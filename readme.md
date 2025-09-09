
# Bicep Scripts Repository

This repository contains a collection of reusable [Bicep](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/overview) modules and shared resources designed to streamline Azure infrastructure deployments.

## 🔧 Structure

### 📁 Modules/

Modular Bicep scripts for deploying common Azure resources


### 📁 Modules/.shared/

Shared templates and JSON configurations

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



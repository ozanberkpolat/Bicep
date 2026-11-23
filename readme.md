
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

## 🚀 Deployment

Markdown files have been created under each project

## 📦 Prerequisites

- Azure CLI with Bicep installed: `az bicep install`
- Properly configured Azure subscription and permissions

## ✅ Status

This repo is actively maintained and used for deploying Azure workloads using modular, repeatable, and scalable infrastructure as code (IaC) practices.


## ✍️ Author

Maintained by [ozanberkpolat](https://github.com/ozanberkpolat)



## Wave 2 additions

### New modules (`Modules/`)

| File | What it does |
|---|---|
| `deployVM.bicep` (extended) | Generic VM on AVM. `adminUsername` is now required. Optional: Trusted Launch, data disks, static IP, SSH key, maintenance configuration, backup enrolment, DCR association, Windows Server 2025 / Ubuntu 24.04 / RHEL 10 images. |
| `deployVMStaticNic.bicep` | VM plus NIC as plain resources: static IP, Trusted Launch, Hybrid Benefit, data disks, random unknown admin password by default. |
| `deployAvdHostPool.bicep` | AVD host pool, app group (Desktop or RemoteApp), workspace, RemoteApps, user assignment, diagnostics. |
| `deployAvdSubnet.bicep` | AVD subnet in an existing VNet with the standard AVD NSG and an optional route table to an NVA. |
| `deployAvdSessionHost.bicep` | Entra-joined AVD session hosts registered in an existing host pool. |
| `deployVMInsightsDCR.bicep` | VM Insights data collection rule (InsightsMetrics) with optional VM associations. |
| `deploySpokeVnet.bicep` | Spoke VNet, route table to an NVA, spoke-side hub peering. |
| `deployHubSpokeLink.bicep` | Hub-side peering and routes to a new spoke in the hub route tables. |

### New examples (`Projects/`)

| Folder | What it shows |
|---|---|
| `AVD-HostPool` | Management plane, dedicated subnet and optional session hosts. |
| `Identity-Prod` | User-assigned managed identities and RBAC at subscription and resource group scope. |
| `ResourceOrganization-Prod` | Resource groups with naming, tagging and required-tag policy (subscription scope). |
| `HubSpoke-Spoke` | Adding a spoke to an existing hub (both peering sides and the hub routes). |
| `DomainLab` | Training domain lab: VNet, DC promoting a new forest by Run Command, joined member server, RDP from one source range, auto-shutdown. |
| `AVD-RemoteApp-Lab` | RemoteApp host pool, workspace, lab VNet/subnet, Entra-joined session host, user assignment, auto-shutdown (uses the AVD modules). |

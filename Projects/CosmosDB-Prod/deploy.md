# Bicep Deployment Guide

This guide explains how to authenticate with Azure, select a subscription, and deploy Bicep templates at both the **resource group** and **subscription** scope.

---

## Prerequisites

- **Azure CLI** version 2.45.0 or later  
- Permissions:
  - Contributor or Owner role on the target Resource Group for group deployments  
  - Contributor or Owner role at the Subscription level for subscription deployments  
- Bicep files: `main.bicep` and `main.bicepparam` must exist in your working directory.

---

## 1. Login to Azure

```bash
az login
```

---

## 2. Set Subscription

```bash
az account set --subscription Gunvor-DevOps-Prod
```

---

## 3. Deploy at Resource Group Scope

```bash
az deployment group create   --resource-group RESOURCE-GROUP-NAME   --template-file main.bicep   --parameters main.bicepparam
```

---

## 4. Deploy at Subscription Scope

```bash
az deployment sub create   --location SwitzerlandNorth   --template-file main.bicep   --parameters main.bicepparam
```

---

## Notes

- Replace `SUBSCRIPTION-NAME` with the actual subscription name or ID.  
- Replace `RESOURCE-GROUP-NAME` with the target resource group.  
- Ensure your `main.bicep` and `main.bicepparam` files are correct and validated before deployment.  

# Day 11 — Infrastructure as Code — Terraform & Bicep

> Goal: provision Azure infrastructure declaratively and automate it in a pipeline.

---

## Objectives

By the end of this day you will:

- Understand Infrastructure as Code (IaC) and its benefits
- Write Terraform to provision Azure resources
- Compare Terraform with Bicep/ARM
- Run terraform in a pipeline with remote state

---

## Concepts

### Why IaC

- Repeatable, versioned, reviewable infrastructure
- No manual clicking; environments are identical
- Plan before apply to preview changes

### Terraform basics

- Providers, resources, variables, outputs
- State tracks what exists; store it remotely (GCS/Azure Storage)
- Modules make configurations reusable

### Terraform vs Bicep

- Terraform: multi-cloud, mature ecosystem, HCL
- Bicep: Azure-native, transpiles to ARM, tight Azure integration

---

## Hands-on

1. Write Terraform to create a resource group and storage account
2. Run init/plan/apply locally
3. Configure a remote backend for state
4. Add a terraform stage to the pipeline

---

## Commands / snippets

```
provider "azurerm" {
  features {}
}
resource "azurerm_resource_group" "rg" {
  name     = "nexpay-rg"
  location = "westeurope"
}

# CLI
terraform init
terraform plan
terraform apply -auto-approve
```

> Add your own notes, screenshots, and expanded examples in this section.

---

## Homework

- Provision the AKS cluster from Day 10 with Terraform
- Move state to a remote backend
- Reproduce one resource in Bicep and compare

---

## Recap

- IaC makes infrastructure repeatable and reviewable
- Terraform + remote state gives safe, shared automation
- Bicep is the Azure-native alternative worth knowing
- Next: secure and observe everything, then build the capstone


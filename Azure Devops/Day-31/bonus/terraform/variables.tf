# =============================================================================
# SkillPulse Azure VM - Variable Definitions
# =============================================================================
# Variables make the Terraform configuration reusable and customizable.
# Each variable has a description, type, and a sensible default value.
#
# You can override these defaults in three ways:
#   1. Command line:  terraform apply -var="location=East US"
#   2. tfvars file:   Create a terraform.tfvars file with key=value pairs
#   3. Environment:   export TF_VAR_location="East US"
# =============================================================================

# -----------------------------------------------------------------------------
# General Settings
# -----------------------------------------------------------------------------

variable "location" {
  description = "Azure region where all resources will be deployed. Choose a region close to your users for lower latency."
  type        = string
  default     = "Central India"

  validation {
    condition     = length(var.location) > 0
    error_message = "Location must not be empty."
  }
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod). Used in resource names and tags for organization."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "resource_group_name" {
  description = "Name of the Azure Resource Group. All resources will be created inside this group."
  type        = string
  default     = "rg-skillpulse-dev"
}

# -----------------------------------------------------------------------------
# Virtual Machine Settings
# -----------------------------------------------------------------------------

variable "vm_size" {
  description = "Size (SKU) of the Azure VM. Standard_B1s is the cheapest option and is eligible for the Azure free tier. For better performance, try Standard_B2s or Standard_B2ms."
  type        = string
  default     = "Standard_B1s"
}

variable "admin_username" {
  description = "Username for the VM admin account. This is the user you will SSH into the VM as."
  type        = string
  default     = "azureuser"

  validation {
    condition     = length(var.admin_username) >= 1 && length(var.admin_username) <= 64
    error_message = "Admin username must be between 1 and 64 characters."
  }
}

variable "ssh_public_key" {
  description = "SSH public key content (the actual key string). If provided, this takes priority over ssh_public_key_path. Leave empty to use the file path instead."
  type        = string
  default     = ""
  sensitive   = true
}

variable "ssh_public_key_path" {
  description = "Path to your SSH public key file on disk. Used only if ssh_public_key is empty. Defaults to the standard location (~/.ssh/id_rsa.pub)."
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "os_disk_size_gb" {
  description = "Size of the OS disk in GB. 30 GB is plenty for SkillPulse. Increase if you need more space for Docker images or logs."
  type        = number
  default     = 30

  validation {
    condition     = var.os_disk_size_gb >= 30 && var.os_disk_size_gb <= 1024
    error_message = "OS disk size must be between 30 and 1024 GB."
  }
}

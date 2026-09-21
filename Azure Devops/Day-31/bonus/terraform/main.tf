# =============================================================================
# SkillPulse Azure VM - Terraform Configuration
# =============================================================================
# This Terraform configuration provisions a complete Azure VM environment
# for the SkillPulse application, including networking, security, and the VM
# itself with Docker pre-installed.
#
# Usage:
#   terraform init
#   terraform plan
#   terraform apply
#
# Cleanup:
#   terraform destroy
# =============================================================================

# -----------------------------------------------------------------------------
# Terraform Settings & Provider Configuration
# -----------------------------------------------------------------------------

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
  }

  # Uncomment the block below to store Terraform state in Azure Storage.
  # This is recommended for team environments and CI/CD pipelines.
  # See the bonus chapter README for setup instructions.
  #
  # backend "azurerm" {
  #   resource_group_name  = "rg-terraform-state"
  #   storage_account_name = "stskillpulsetfstate"
  #   container_name       = "tfstate"
  #   key                  = "skillpulse.terraform.tfstate"
  # }
}

provider "azurerm" {
  features {}
}

# -----------------------------------------------------------------------------
# Local Values
# -----------------------------------------------------------------------------
# Locals let us define computed values that are reused throughout the config.

locals {
  # Common tags applied to every resource for organization and cost tracking
  common_tags = {
    project     = "SkillPulse"
    environment = var.environment
    managed_by  = "terraform"
    course      = "azure-devops-zero-to-hero"
  }

  # Consistent naming convention: <resource-type>-skillpulse-<environment>
  name_prefix = "skillpulse-${var.environment}"
}

# -----------------------------------------------------------------------------
# Resource Group
# -----------------------------------------------------------------------------
# A resource group is a logical container for all Azure resources.
# Everything we create will live inside this resource group.

resource "azurerm_resource_group" "skillpulse" {
  name     = var.resource_group_name
  location = var.location
  tags     = local.common_tags
}

# -----------------------------------------------------------------------------
# Virtual Network
# -----------------------------------------------------------------------------
# The VNet is your private network in Azure. Think of it as your own
# isolated neighborhood in the cloud.

resource "azurerm_virtual_network" "skillpulse" {
  name                = "vnet-${local.name_prefix}"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.skillpulse.location
  resource_group_name = azurerm_resource_group.skillpulse.name
  tags                = local.common_tags
}

# -----------------------------------------------------------------------------
# Subnet
# -----------------------------------------------------------------------------
# A subnet is a range of IP addresses within the VNet. Our VM will be
# placed in this subnet.

resource "azurerm_subnet" "skillpulse" {
  name                 = "snet-${local.name_prefix}"
  resource_group_name  = azurerm_resource_group.skillpulse.name
  virtual_network_name = azurerm_virtual_network.skillpulse.name
  address_prefixes     = ["10.0.1.0/24"]
}

# -----------------------------------------------------------------------------
# Public IP Address
# -----------------------------------------------------------------------------
# This gives the VM a public IP so it can be accessed from the internet.
# Without this, the VM would only be reachable from within the VNet.

resource "azurerm_public_ip" "skillpulse" {
  name                = "pip-${local.name_prefix}"
  resource_group_name = azurerm_resource_group.skillpulse.name
  location            = azurerm_resource_group.skillpulse.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.common_tags
}

# -----------------------------------------------------------------------------
# Network Security Group (NSG)
# -----------------------------------------------------------------------------
# The NSG acts as a firewall for the VM. We define rules to allow specific
# traffic (SSH, HTTP, HTTPS) and block everything else by default.

resource "azurerm_network_security_group" "skillpulse" {
  name                = "nsg-${local.name_prefix}"
  location            = azurerm_resource_group.skillpulse.location
  resource_group_name = azurerm_resource_group.skillpulse.name
  tags                = local.common_tags

  # --- Rule: Allow SSH (port 22) ---
  # Needed to connect to the VM for management and agent setup.
  # WARNING: In production, restrict source_address_prefix to your IP address
  # or use Azure Bastion instead of opening SSH to the internet.
  security_rule {
    name                       = "AllowSSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # --- Rule: Allow HTTP (port 80) ---
  # SkillPulse serves the frontend and API on port 80 via Nginx.
  security_rule {
    name                       = "AllowHTTP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # --- Rule: Allow HTTPS (port 443) ---
  # For future use if you add TLS/SSL certificates.
  security_rule {
    name                       = "AllowHTTPS"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# -----------------------------------------------------------------------------
# NSG <-> Subnet Association
# -----------------------------------------------------------------------------
# Attach the NSG to the subnet so its rules apply to all resources in
# the subnet.

resource "azurerm_subnet_network_security_group_association" "skillpulse" {
  subnet_id                 = azurerm_subnet.skillpulse.id
  network_security_group_id = azurerm_network_security_group.skillpulse.id
}

# -----------------------------------------------------------------------------
# Network Interface (NIC)
# -----------------------------------------------------------------------------
# The NIC connects the VM to the network. It binds together the subnet
# and the public IP address.

resource "azurerm_network_interface" "skillpulse" {
  name                = "nic-${local.name_prefix}"
  location            = azurerm_resource_group.skillpulse.location
  resource_group_name = azurerm_resource_group.skillpulse.name
  tags                = local.common_tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.skillpulse.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.skillpulse.id
  }
}

# -----------------------------------------------------------------------------
# Linux Virtual Machine
# -----------------------------------------------------------------------------
# This is the main event -- the VM that will host SkillPulse.
# It uses Ubuntu 22.04 LTS, authenticates via SSH key, and runs a startup
# script (custom_data) that installs Docker and Docker Compose.

resource "azurerm_linux_virtual_machine" "skillpulse" {
  name                = "vm-${local.name_prefix}"
  resource_group_name = azurerm_resource_group.skillpulse.name
  location            = azurerm_resource_group.skillpulse.location
  size                = var.vm_size
  admin_username      = var.admin_username

  # Attach the network interface we created above
  network_interface_ids = [
    azurerm_network_interface.skillpulse.id,
  ]

  # SSH key authentication (more secure than passwords)
  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key != "" ? var.ssh_public_key : file(var.ssh_public_key_path)
  }

  # Disable password authentication for better security
  disable_password_authentication = true

  # OS Disk configuration
  os_disk {
    name                 = "osdisk-${local.name_prefix}"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = var.os_disk_size_gb
  }

  # Ubuntu 22.04 LTS image (same as what we used in Chapter 7)
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  # Startup script that runs when the VM first boots.
  # This installs Docker, Docker Compose, Git, and creates the project
  # directory -- exactly what the setup-vm.sh script does, but automated.
  custom_data = base64encode(<<-SETUP_SCRIPT
    #!/bin/bash
    set -e

    echo "========================================" | tee /var/log/skillpulse-setup.log
    echo "  SkillPulse VM Setup (via Terraform)"   | tee -a /var/log/skillpulse-setup.log
    echo "========================================" | tee -a /var/log/skillpulse-setup.log

    # Update system packages
    echo "[1/5] Updating system packages..." | tee -a /var/log/skillpulse-setup.log
    apt-get update && apt-get upgrade -y 2>&1 | tee -a /var/log/skillpulse-setup.log

    # Install Docker
    echo "[2/5] Installing Docker..." | tee -a /var/log/skillpulse-setup.log
    apt-get install -y docker.io 2>&1 | tee -a /var/log/skillpulse-setup.log
    systemctl start docker
    systemctl enable docker
    usermod -aG docker ${var.admin_username}

    # Install Docker Compose
    echo "[3/5] Installing Docker Compose..." | tee -a /var/log/skillpulse-setup.log
    apt-get install -y docker-compose-v2 2>&1 | tee -a /var/log/skillpulse-setup.log

    # Install Git
    echo "[4/5] Installing Git..." | tee -a /var/log/skillpulse-setup.log
    apt-get install -y git 2>&1 | tee -a /var/log/skillpulse-setup.log

    # Create project directory
    echo "[5/5] Creating project directory..." | tee -a /var/log/skillpulse-setup.log
    mkdir -p /opt/skillpulse
    chown ${var.admin_username}:${var.admin_username} /opt/skillpulse

    echo "" | tee -a /var/log/skillpulse-setup.log
    echo "========================================" | tee -a /var/log/skillpulse-setup.log
    echo "  VM Setup Complete!"                     | tee -a /var/log/skillpulse-setup.log
    echo "========================================" | tee -a /var/log/skillpulse-setup.log
  SETUP_SCRIPT
  )

  tags = local.common_tags
}

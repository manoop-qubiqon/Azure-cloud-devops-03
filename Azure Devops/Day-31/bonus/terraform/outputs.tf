# =============================================================================
# SkillPulse Azure VM - Output Values
# =============================================================================
# Outputs display useful information after Terraform finishes creating
# resources. They are printed to the terminal after `terraform apply`
# and can be queried later with `terraform output`.
#
# These outputs give you everything you need to connect to and use the VM.
# =============================================================================

# -----------------------------------------------------------------------------
# VM Connection Info
# -----------------------------------------------------------------------------

output "vm_public_ip" {
  description = "Public IP address of the SkillPulse VM. Use this to access the application in your browser (http://<ip>) or to SSH into the VM."
  value       = azurerm_public_ip.skillpulse.ip_address
}

output "ssh_command" {
  description = "Ready-to-use SSH command to connect to the VM. Just copy and paste this into your terminal."
  value       = "ssh ${var.admin_username}@${azurerm_public_ip.skillpulse.ip_address}"
}

output "skillpulse_url" {
  description = "URL to access the SkillPulse application once it is deployed and running on the VM."
  value       = "http://${azurerm_public_ip.skillpulse.ip_address}"
}

# -----------------------------------------------------------------------------
# Resource Info
# -----------------------------------------------------------------------------

output "resource_group_name" {
  description = "Name of the resource group containing all SkillPulse resources. Useful for Azure CLI commands and portal navigation."
  value       = azurerm_resource_group.skillpulse.name
}

output "vm_name" {
  description = "Name of the virtual machine in Azure."
  value       = azurerm_linux_virtual_machine.skillpulse.name
}

output "vm_size" {
  description = "The VM size (SKU) that was deployed."
  value       = azurerm_linux_virtual_machine.skillpulse.size
}

output "vm_admin_username" {
  description = "The admin username configured on the VM."
  value       = azurerm_linux_virtual_machine.skillpulse.admin_username
}

# -----------------------------------------------------------------------------
# Networking Info
# -----------------------------------------------------------------------------

output "virtual_network_name" {
  description = "Name of the virtual network."
  value       = azurerm_virtual_network.skillpulse.name
}

output "subnet_id" {
  description = "ID of the subnet where the VM is deployed. Useful if you want to add more resources to the same subnet."
  value       = azurerm_subnet.skillpulse.id
}

output "network_security_group_name" {
  description = "Name of the Network Security Group attached to the subnet."
  value       = azurerm_network_security_group.skillpulse.name
}

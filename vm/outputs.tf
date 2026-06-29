output "admin_ssh_key_public" {
  description = "The generated public key data in PEM format"
  value       = var.disable_password_authentication == true && var.generate_admin_ssh_key == true ? tls_private_key.rsa[0].public_key_openssh : null
}

output "admin_ssh_key_private" {
  description = "The generated private key data in PEM format"
  sensitive   = true
  value       = var.disable_password_authentication == true && var.generate_admin_ssh_key == true ? tls_private_key.rsa[0].private_key_pem : null
}

output "linux_vm_password" {
  description = "Password for the Linux VM"
  sensitive   = true
  value       = var.disable_password_authentication == false && var.admin_password == null ? element(concat(random_password.passwd[*].result, [""]), 0) : var.admin_password
}

output "linux_vm_public_ips" {
  description = "Public IP's map for the all Linux Virtual Machines"
  value       = zipmap(azurerm_linux_virtual_machine.linux_vm[*].name, azurerm_linux_virtual_machine.linux_vm[*].public_ip_address)
}

output "linux_vm_private_ips" {
  description = "Private IP's map for the all Linux Virtual Machines"
  value       = zipmap(azurerm_linux_virtual_machine.linux_vm[*].name, azurerm_linux_virtual_machine.linux_vm[*].private_ip_address)
}

output "linux_virtual_machine_ids" {
  description = "The resource id's of all Linux Virtual Machine."
  value       = concat(azurerm_linux_virtual_machine.linux_vm[*].id, [""])
}

output "network_security_group_id" {
  description = "The ID of the NIC-level NSG created by this module, or null if none was created."
  value       = length(azurerm_network_security_group.nic_nsg) > 0 ? azurerm_network_security_group.nic_nsg[0].id : null
}

output "vm_extension_ids" {
  description = "Map of VM extension names to their resource IDs"
  value       = { for k, v in azurerm_virtual_machine_extension.extension : k => v.id }
}

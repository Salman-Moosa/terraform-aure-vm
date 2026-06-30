###############################################################################
# example/outputs.tf
###############################################################################

output "linux_virtual_machine_ids" {
  description = "Resource IDs of all Linux Virtual Machines"
  value       = module.virtual_machine.linux_virtual_machine_ids
}

output "linux_vm_private_ips" {
  description = "Private IP addresses of the Linux VMs"
  value       = module.virtual_machine.linux_vm_private_ips
}

output "linux_vm_public_ips" {
  description = "Public IP addresses of the Linux VMs (null if no public IP assigned)"
  value       = module.virtual_machine.linux_vm_public_ips
}

output "admin_ssh_key_public" {
  description = "Generated SSH public key (OpenSSH format)"
  value       = module.virtual_machine.admin_ssh_key_public
}

output "admin_ssh_key_private" {
  description = "Generated SSH private key (PEM) sensitive"
  sensitive   = true
  value       = module.virtual_machine.admin_ssh_key_private
}

output "network_security_group_id" {
  description = "ID of the NIC-level NSG created by the module, or null"
  value       = module.virtual_machine.network_security_group_id
}

output "vm_extension_ids" {
  description = "Map of VM extension names to their resource IDs"
  value       = module.virtual_machine.vm_extension_ids
}
###############################################################################
# example/main.tf
#
# Demonstrates how to call the local VM module using an EXISTING VNet/subnet.
#
# Environment:

###############################################################################





# ── Local module call ─────────────────────────────────────────────────────────

module "virtual_machine" {
  source = "../" # path to the local module root

  # ── Resource Group ─────────────────────────────────────────────────────────

  resource_group_name = var.resource_group_name
  location            = var.location
  resource_prefix     = var.resource_prefix

  # ── VM identity ────────────────────────────────────────────────────────────
  virtual_machine_name = var.virtual_machine_name
  virtual_machine_size = var.virtual_machine_size
  admin_username       = var.admin_username
  vm_availability_zone = var.vm_availability_zone
  custom_data          = var.custom_data

  # ── OS image ─────────────────────────────────────────────────────────────
  #  defaults to Ubuntu 22.04 LTS.
  source_image_publisher = var.source_image_publisher
  source_image_offer     = var.source_image_offer
  source_image_sku       = var.source_image_sku
  source_image_version   = var.source_image_version

  # ── SSH authentication ─────────────────────────────────────────────────────
  generate_admin_ssh_key          = var.generate_admin_ssh_key
  disable_password_authentication = var.disable_password_authentication

  # ── Networking ─────────────────────────────────────────────────────────────
  # Pass the subnet resource ID directly from the VNet module output.
  # NSG: either provide nsg_rules (new NSG) or existing_nsg_id, or leave both
  # empty to rely on the subnet-level NSG set by the VNet module.
  subnet_id       = var.subnet_id
  nsg_rules       = var.nsg_rules
  existing_nsg_id = var.existing_nsg_id

  # ── Public IP (optional) ──────────────────────────────────────────────────
  create_public_ip_address    = var.create_public_ip_address
  public_ip_allocation_method = var.public_ip_allocation_method
  public_ip_sku               = var.public_ip_sku

  # ── Private IP (optional) ─────────────────────────────────────────────────
  private_ip_address_allocation_type = var.private_ip_address_allocation_type
  private_ip_address                 = var.private_ip_address

  # ── OS Disk ────────────────────────────────────────────────────────────────
  os_disk_storage_account_type = var.os_disk_storage_account_type
  os_disk_caching              = var.os_disk_caching
  disk_size_gb                 = var.disk_size_gb

  # ── Boot diagnostics ──────────────────────────────────────────────────────────────
  # Uses Azure managed boot diagnostics (storage_account_uri = null).
  # No extra storage account is created unless create_storage_account = true.
  enable_boot_diagnostics = var.enable_boot_diagnostics
  create_storage_account  = var.create_storage_account

  # ── Data disks (optional) ────────────────────────────────────────────────────────
  data_disks = var.data_disks

  # ── Key Vault – creates vault + stores SSH private key as a secret ─────────────
  # Reads from terraform.tfvars. Remove this block if you don’t need secret storage.
  key_vault = var.key_vault

  # ── Extensions ────────────────────────────────────────────────────────────
  extensions = var.extensions

  # ── Log Analytics (optional) ────────────────────────────────────────────
  # Uncomment when you have a Log Analytics workspace.
  #
  # deploy_log_analytics_agent = true
  # log_analytics_workspace_id = data.azurerm_log_analytics_workspace.example.id

  # ── Tags ───────────────────────────────────────────────────────────────────
  tags = var.tags
}
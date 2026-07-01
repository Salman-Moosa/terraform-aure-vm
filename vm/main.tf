locals {
  resource_group_name = var.resource_group_name
  resource_prefix     = var.resource_prefix == "" ? local.resource_group_name : var.resource_prefix

  # This module creates exactly 1 Linux VM.
  instances_count = 1

  storage_account_name = var.storage_account_name != null && var.storage_account_name != "" ? format("%s", lower(replace(var.storage_account_name, "/[[:^alnum:]]/", ""))) : format("%sstvhd", lower(replace(local.resource_prefix, "/[[:^alnum:]]/", "")))

  # Derived: is any NIC-level NSG active
  nic_nsg_create   = length(var.nsg_rules) > 0
  nic_nsg_existing = var.existing_nsg_id != null && length(var.nsg_rules) == 0
  attach_nsg       = local.nic_nsg_create || local.nic_nsg_existing

  vm_data_disks = { for idx, data_disk in var.data_disks : data_disk.name => {
    idx : idx,
    data_disk : data_disk,
    }
  }

}

#---------------------------------------------------------------
# Generates SSH2 key Pair for Linux VM's (Dev Environment only)
#---------------------------------------------------------------

resource "tls_private_key" "rsa" {
  count     = var.generate_admin_ssh_key ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}


#---------------------------------------
# Key vault and permission for read and write
#---------------------------------------
data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "this" {
  count                      = var.key_vault != null ? 1 : 0
  name                       = var.key_vault.name
  location                   = var.location
  resource_group_name        = try(coalesce(var.key_vault.resource_group_name, local.resource_group_name), local.resource_group_name)
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = try(var.key_vault.sku_name, "standard")
  rbac_authorization_enabled = true
  purge_protection_enabled   = var.key_vault_purge_protection_enabled
  soft_delete_retention_days = var.key_vault_soft_delete_retention_days
  tags                       = merge({ "VirtualMachineName" = var.virtual_machine_name }, var.tags)
}

###--- RBAC: deploying identity (pipeline SP) → Secrets Officer ---------------

resource "azurerm_role_assignment" "kv_deployer_officer" {
  count                = var.key_vault != null ? 1 : 0
  scope                = azurerm_key_vault.this[0].id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

###--- RBAC: additional Secrets Officers (write access) -----------------------

resource "azurerm_role_assignment" "kv_secrets_officer" {
  for_each             = var.key_vault != null ? { for o in try(var.key_vault.secret_officers, []) : o.name => o } : {}
  scope                = azurerm_key_vault.this[0].id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = each.value.principal_id
}

###--- RBAC: Secrets Readers (read-only access) -------------------------------

resource "azurerm_role_assignment" "kv_secrets_reader" {
  for_each             = var.key_vault != null ? { for r in try(var.key_vault.secret_readers, []) : r.name => r } : {}
  scope                = azurerm_key_vault.this[0].id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = each.value.principal_id
}

###--- Secrets ----------------------------------------------------------------

resource "azurerm_key_vault_secret" "admin_login" {
  count        = var.key_vault != null ? 1 : 0
  name         = "${var.virtual_machine_name}-admin-login"
  value        = var.admin_username
  key_vault_id = azurerm_key_vault.this[0].id
  content_type = "text/plain"
  tags         = var.tags

  depends_on = [azurerm_role_assignment.kv_deployer_officer]
}

resource "azurerm_key_vault_secret" "admin_password" {
  count        = var.key_vault != null && var.disable_password_authentication == false ? 1 : 0
  name         = "${var.virtual_machine_name}-admin-password"
  value        = var.admin_password == null ? element(concat(random_password.passwd[*].result, [""]), 0) : var.admin_password
  key_vault_id = azurerm_key_vault.this[0].id
  content_type = "text/plain"
  tags         = var.tags

  depends_on = [
    azurerm_role_assignment.kv_deployer_officer
  ]
}

resource "azurerm_key_vault_secret" "admin_ssh_key" {
  count        = var.key_vault != null && var.disable_password_authentication == true && var.generate_admin_ssh_key ? 1 : 0
  name         = "${var.virtual_machine_name}-admin-ssh-key"
  value        = var.generate_admin_ssh_key ? tls_private_key.rsa[0].private_key_pem : ""
  key_vault_id = azurerm_key_vault.this[0].id
  content_type = "text/plain"
  tags         = var.tags

  depends_on = [
    azurerm_role_assignment.kv_deployer_officer
  ]
}



#----------------------------------------------------------
# Random Resources for Password generation 
#----------------------------------------------------------

resource "random_password" "passwd" {
  count       = var.disable_password_authentication == false && var.admin_password == null ? 1 : 0
  length      = var.random_password_length
  min_upper   = 4
  min_lower   = 2
  min_numeric = 4
  special     = false
}

#-----------------------------------------------
# Storage Account for Disk Storage
#-----------------------------------------------

data "azurerm_resource_group" "storage_rg" {
  count = var.storage_account_resource_group_name != null ? 1 : 0

  name = var.storage_account_resource_group_name
}



resource "azurerm_storage_account" "storage" {
  count = var.create_storage_account ? 1 : 0

  name                     = local.storage_account_name
  resource_group_name      = var.storage_account_resource_group_name != null ? var.storage_account_resource_group_name : local.resource_group_name
  location                 = var.location
  account_kind             = "StorageV2"
  account_tier             = var.storage_account_tier_type
  account_replication_type = var.storage_account_replication_type

  tags = var.tags



}



#-----------------------------------
# Public IP for Virtual Machine
#-----------------------------------

resource "azurerm_public_ip" "pip" {
  count = var.create_public_ip_address ? 1 : 0

  name                = lower("vm-${var.virtual_machine_name}-pip")
  resource_group_name = local.resource_group_name
  location            = var.location
  allocation_method   = var.public_ip_allocation_method
  sku                 = var.public_ip_sku
  sku_tier            = var.public_ip_sku_tier
  domain_name_label   = var.domain_name_label
  public_ip_prefix_id = var.public_ip_prefix_id

  tags = var.tags

  lifecycle {
    ignore_changes = [tags, ip_tags]
  }
}

#---------------------------------------
# Network Interface for Virtual Machine
#---------------------------------------

resource "azurerm_network_interface" "nic" {
  name                           = lower("vm-${var.virtual_machine_name}-nic")
  resource_group_name            = local.resource_group_name
  location                       = var.location
  dns_servers                    = var.dns_servers
  ip_forwarding_enabled          = var.enable_ip_forwarding
  accelerated_networking_enabled = var.enable_accelerated_networking
  internal_dns_name_label        = var.internal_dns_name_label

  tags = var.tags

  ip_configuration {
    name                          = lower("vm-${var.virtual_machine_name}-nic-ipconfig")
    primary                       = true
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = var.private_ip_address_allocation_type
    private_ip_address            = var.private_ip_address_allocation_type == "Static" ? var.private_ip_address : null
    public_ip_address_id          = var.create_public_ip_address ? azurerm_public_ip.pip[0].id : null
  }

  lifecycle {
    ignore_changes = [tags]
  }
}

#---------------------------------------------------------------
# Network Security Group for Virtual Machine NIC
#
# Three modes — controlled by two variables:
#   1. nsg_rules has entries   → creates a new NSG with those rules, attaches to NIC
#   2. existing_nsg_id is set  → attaches that existing NSG to the NIC
#   3. both empty / null       → no NIC-level NSG; subnet NSG from VNet module applies
#---------------------------------------------------------------

resource "azurerm_network_security_group" "nic_nsg" {
  count = local.nic_nsg_create ? 1 : 0

  name                = lower("vm-${var.virtual_machine_name}-nsg")
  resource_group_name = local.resource_group_name
  location            = var.location

  tags = var.tags

  dynamic "security_rule" {
    # map(object) — each rule keyed by name; adding/removing one rule is stable
    for_each = var.nsg_rules
    content {
      name                       = security_rule.key
      priority                   = security_rule.value.priority
      direction                  = security_rule.value.direction
      access                     = security_rule.value.access
      protocol                   = security_rule.value.protocol
      source_port_range          = security_rule.value.source_port_range
      destination_port_range     = security_rule.value.destination_port_range
      source_address_prefix      = security_rule.value.source_address_prefix
      destination_address_prefix = security_rule.value.destination_address_prefix
      description                = security_rule.value.description
    }
  }
}

# Attach NSG to NIC — count-based, works for newly created or existing NSG
resource "azurerm_network_interface_security_group_association" "nic_nsg" {
  count = local.attach_nsg ? 1 : 0

  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = local.nic_nsg_create ? azurerm_network_security_group.nic_nsg[0].id : var.existing_nsg_id
}


#---------------------------------------
# Linux Virtual machine
#---------------------------------------

resource "azurerm_linux_virtual_machine" "linux_vm" {
  count = local.instances_count

  name = lower(var.virtual_machine_name)

  computer_name                   = substr(lower(replace(var.virtual_machine_name, "/[^0-9A-Za-z\\-]/", "")), 0, 64)
  resource_group_name             = local.resource_group_name
  location                        = var.location
  size                            = var.virtual_machine_size
  admin_username                  = var.admin_username
  admin_password                  = var.disable_password_authentication == false && var.admin_password == null ? element(concat(random_password.passwd[*].result, [""]), 0) : var.admin_password
  disable_password_authentication = var.disable_password_authentication
  network_interface_ids           = [azurerm_network_interface.nic.id]
  source_image_id                 = var.source_image_id
  provision_vm_agent              = true
  allow_extension_operations      = true
  dedicated_host_id               = var.dedicated_host_id
  custom_data                     = var.custom_data != null ? base64encode(var.custom_data) : null
  user_data                       = var.user_data != null ? base64encode(var.user_data) : null
  encryption_at_host_enabled      = var.enable_encryption_at_host
  zone                            = var.vm_availability_zone
  vtpm_enabled                    = var.enable_tpm
  secure_boot_enabled             = var.enable_secure_boot

  tags = var.tags

  dynamic "admin_ssh_key" {
    for_each = var.disable_password_authentication ? [1] : []

    content {
      username   = var.admin_username
      public_key = var.admin_ssh_key_data == null ? tls_private_key.rsa[0].public_key_openssh : file(var.admin_ssh_key_data)
    }
  }


  dynamic "source_image_reference" {
    for_each = var.source_image_id != null ? [] : [1]

    content {
      publisher = var.custom_image != null ? var.custom_image.publisher : var.source_image_publisher
      offer     = var.custom_image != null ? var.custom_image.offer : var.source_image_offer
      sku       = var.custom_image != null ? var.custom_image.sku : var.source_image_sku
      version   = var.custom_image != null ? var.custom_image.version : var.source_image_version
    }
  }

  os_disk {
    storage_account_type      = var.os_disk_storage_account_type
    caching                   = var.os_disk_caching
    disk_encryption_set_id    = var.disk_encryption_set_id
    disk_size_gb              = var.disk_size_gb
    write_accelerator_enabled = var.enable_os_disk_write_accelerator
    name                      = var.os_disk_name
  }

  additional_capabilities {
    ultra_ssd_enabled = var.enable_ultra_ssd_data_disk_storage_support
  }

  dynamic "identity" {
    for_each = var.managed_identity_type != null ? [1] : []

    content {
      type         = var.managed_identity_type
      identity_ids = var.managed_identity_type == "UserAssigned" || var.managed_identity_type == "SystemAssigned, UserAssigned" ? var.managed_identity_ids : null
    }
  }

  dynamic "boot_diagnostics" {
    for_each = var.enable_boot_diagnostics ? [1] : []

    content {
      # Passing null tells Azure to use its own managed storage account for boot
      # diagnostics – no storage resource is created in your subscription.
      # Set create_storage_account = true in tfvars to use a custom storage account.
      storage_account_uri = var.create_storage_account ? element(concat(azurerm_storage_account.storage[*].primary_blob_endpoint, [""]), 0) : null
    }
  }

  lifecycle {
    ignore_changes = [
      tags,
    ]
  }


}


#---------------------------------------
# Virtual machine data disks
#---------------------------------------

resource "azurerm_managed_disk" "data_disk" {
  for_each = local.vm_data_disks

  name                 = "vm-${var.virtual_machine_name}-datadisk-${each.value.idx}"
  resource_group_name  = local.resource_group_name
  location             = var.location
  storage_account_type = lookup(each.value.data_disk, "storage_account_type", "StandardSSD_LRS")
  create_option        = "Empty"
  disk_size_gb         = each.value.data_disk.disk_size_gb

  tags = merge({ "ResourceName" = "vm-${var.virtual_machine_name}-datadisk-${each.value.idx}" }, var.tags)

  lifecycle {
    ignore_changes = [
      tags,
    ]
  }

}

resource "azurerm_virtual_machine_data_disk_attachment" "data_disk" {
  for_each = local.vm_data_disks

  managed_disk_id    = azurerm_managed_disk.data_disk[each.key].id
  virtual_machine_id = azurerm_linux_virtual_machine.linux_vm[0].id
  lun                = each.value.idx
  caching            = "ReadWrite"

  depends_on = [
    azurerm_linux_virtual_machine.linux_vm
  ]


}


#---------------------------------------
# Virtual machine extensions
#---------------------------------------

resource "azurerm_virtual_machine_extension" "extension" {
  for_each = var.extensions

  name                        = each.key
  virtual_machine_id          = azurerm_linux_virtual_machine.linux_vm[0].id
  publisher                   = each.value.publisher
  type                        = each.value.type
  type_handler_version        = each.value.type_handler_version
  auto_upgrade_minor_version  = each.value.auto_upgrade_minor_version
  automatic_upgrade_enabled   = each.value.automatic_upgrade_enabled
  failure_suppression_enabled = each.value.failure_suppression_enabled

  settings           = try(length(each.value.settings), 0) > 0 ? jsonencode(each.value.settings) : null
  protected_settings = try(length(each.value.protected_settings), 0) > 0 ? jsonencode(each.value.protected_settings) : null

  provision_after_extensions = length(each.value.provision_after_extensions) > 0 ? each.value.provision_after_extensions : null

  tags = var.tags

  depends_on = [
    azurerm_linux_virtual_machine.linux_vm
  ]
}

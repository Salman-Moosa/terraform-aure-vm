###############################################################################
# example/variables.tf
#
# Declarations for every value supplied in terraform.tfvars.
# The example root module passes these straight through to the VM module.
###############################################################################

# ── Resource Group ────────────────────────────────────────────────────────────



variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region – must match the region where the VNet/subnet live"
  type        = string
}

variable "resource_prefix" {
  description = "Optional prefix applied to all resource names"
  type        = string
  default     = ""
}

# ── VM identity ───────────────────────────────────────────────────────────────

variable "virtual_machine_name" {
  description = "Name of the virtual machine"
  type        = string
}

variable "virtual_machine_size" {
  description = "Azure VM SKU (e.g. Standard_B2s)"
  type        = string
  default     = "Standard_B2s"
}

# ── OS Image ──────────────────────────────────────────────────────────────────

variable "admin_username" {
  description = "The username of the local administrator used for the Virtual Machine."
  type        = string
  default     = "azureuser"
}

variable "vm_availability_zone" {
  description = "The Zone in which this Virtual Machine should be created."
  type        = string
  default     = null
}

variable "custom_data" {
  description = <<-EOT
    Cloud-init/bash script to run once on VM creation. Provide exactly one of:
      content = "<plain text script>"
      file    = "<path to script file>"
  EOT
  type = object({
    content = optional(string)
    file    = optional(string)
  })
  default = null

  validation {
    condition = var.custom_data == null || (
      (var.custom_data.content != null) != (var.custom_data.file != null)
    )
    error_message = "Exactly one of custom_data.content or custom_data.file must be set (not both, not neither)."
  }
}


variable "source_image_publisher" {
  description = "Publisher of the VM source image"
  type        = string
  default     = "Canonical"
}

variable "source_image_offer" {
  description = "Offer of the VM source image"
  type        = string
  default     = "ubuntu-22_04-lts"
}

variable "source_image_sku" {
  description = "SKU of the VM source image (e.g. server)"
  type        = string
  default     = "server"
}

variable "source_image_version" {
  description = "Version of the VM source image"
  type        = string
  default     = "latest"
}
# ── Secure Boot ─────────────────────────────────────────────────────────────────

variable "enable_tpm" {
  description = "(Optional) Enable vTPM (virtual Trusted Platform Module) on the virtual machine. Required for Secure Boot. Only supported on Gen2 VM images."
  type        = bool
  default     = true
}

variable "enable_secure_boot" {
  description = "(Optional) Enable Secure Boot on the virtual machine (Trusted Launch). Requires a Gen2 VM image and vtpm_enabled = true."
  type        = bool
  default     = true
}

# ── SSH authentication ────────────────────────────────────────────────────────

variable "generate_admin_ssh_key" {
  description = "Generate an SSH key pair; private key is stored in Key Vault when key_vault is set"
  type        = bool
  default     = true
}

variable "disable_password_authentication" {
  description = "Disable password auth on the VM (recommended)"
  type        = bool
  default     = true
}

# ── Networking ────────────────────────────────────────────────────────────────

variable "subnet_id" {
  description = "Resource ID of the subnet to attach the NIC to (from VNet module output)"
  type        = string
  default     = ""
}

variable "nsg_rules" {
  description = "Map of NSG rules to create and attach to the VM NIC. Leave empty to use subnet-level NSG only."
  type = map(object({
    priority                   = number
    direction                  = string
    access                     = string
    protocol                   = string
    source_port_range          = string
    destination_port_range     = string
    source_address_prefix      = string
    destination_address_prefix = string
    description                = string
  }))
  default = {}
}

variable "existing_nsg_id" {
  description = "Resource ID of an existing NSG to attach to the NIC. Used only when nsg_rules is empty."
  type        = string
  default     = null
}

variable "create_public_ip_address" {
  description = "Create a Public IP Address to associate with the NIC"
  type        = bool
  default     = false
}

variable "public_ip_allocation_method" {
  description = "Allocation method for the Public IP. Static or Dynamic."
  type        = string
  default     = "Static"
}

variable "public_ip_sku" {
  description = "SKU of the Public IP. Standard or Basic."
  type        = string
  default     = "Standard"
}

variable "private_ip_address_allocation_type" {
  description = "Private IP allocation method. Dynamic or Static."
  type        = string
  default     = "Dynamic"
}

variable "private_ip_address" {
  description = "Static private IP address. Only used when private_ip_address_allocation_type = Static."
  type        = string
  default     = null
}

# ── OS Disk ───────────────────────────────────────────────────────────────────

variable "disk_size_gb" {
  description = "The Size of the Internal OS Disk in GB, if you wish to vary from the size used in the image."
  type        = number
  default     = null
}

variable "os_disk_storage_account_type" {
  description = "Storage type for the OS disk"
  type        = string
  default     = "StandardSSD_LRS"
}

variable "os_disk_caching" {
  description = "Caching mode for the OS disk"
  type        = string
  default     = "ReadWrite"
}

# ── Boot Diagnostics ──────────────────────────────────────────────────────────

variable "enable_boot_diagnostics" {
  description = "Enable boot diagnostics (uses Azure managed storage by default)"
  type        = bool
  default     = true
}

variable "create_storage_account" {
  description = "Create a dedicated storage account. Keep false to use Azure managed boot diagnostics."
  type        = bool
  default     = false
}

# ── Data Disks ────────────────────────────────────────────────────────────────

variable "data_disks" {
  description = "List of managed data disks to attach"
  type = list(object({
    name                 = string
    storage_account_type = string
    disk_size_gb         = number
  }))
  default = []
}

# ── Key Vault ─────────────────────────────────────────────────────────────────

variable "key_vault" {
  description = "Key Vault config module creates vault and stores SSH private key. Set null to skip."
  type        = any
  default     = null
}

# ── Extensions ────────────────────────────────────────────────────────────────

variable "extensions" {
  description = "Map of VM extensions to be installed. The key is the extension name."
  type = map(object({
    publisher                   = string
    type                        = string
    type_handler_version        = string
    auto_upgrade_minor_version  = optional(bool, true)
    automatic_upgrade_enabled   = optional(bool, false)
    failure_suppression_enabled = optional(bool, false)
    settings                    = optional(any, {})
    protected_settings          = optional(any, {})
    provision_after_extensions  = optional(list(string), [])
  }))
  default = {}
}

# ── Tags ──────────────────────────────────────────────────────────────────────

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default     = {}
}
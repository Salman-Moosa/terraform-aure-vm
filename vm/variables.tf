variable "resource_group_name" {
  description = "A container that holds related resources for an Azure solution"
  type        = string
  default     = ""
}

variable "location" {
  description = "The location/region to keep all your network resources. To get the list of all locations with table format from azure cli, run 'az account list-locations -o table'"
  type        = string
  default     = ""
}

variable "resource_prefix" {
  description = "(Optional) Prefix to use for all resources created (Defaults to resource_group_name)"
  type        = string
  default     = ""
}



variable "random_password_length" {
  description = "The desired length of random password created by this module"
  default     = 24
}


variable "create_public_ip_address" {
  description = "Create a Public IP Address to associate with the NIC"
  type        = bool
  default     = false
}

variable "public_ip_allocation_method" {
  description = "Defines the allocation method for this IP address. Possible values are `Static` or `Dynamic`"
  type        = string
  default     = "Static"
}

variable "public_ip_sku" {
  description = "The SKU of the Public IP. Accepted values are `Basic` and `Standard`"
  type        = string
  default     = "Standard"
}

variable "domain_name_label" {
  description = "Label for the Domain Name. Will be used to make up the FQDN. If a domain name label is specified, an A DNS record is created for the public IP in the Microsoft Azure DNS system."
  type        = string
  default     = null
}

variable "public_ip_sku_tier" {
  description = "The SKU Tier that should be used for the Public IP. Possible values are `Regional` and `Global`"
  type        = string
  default     = "Regional"
}

variable "public_ip_prefix_id" {
  description = "The public ip prefix resource id"
  type        = string
  default     = null
}

variable "dns_servers" {
  description = "List of dns servers to use for network interface"
  type        = list(string)
  default     = []
}

variable "enable_ip_forwarding" {
  description = "Should IP Forwarding be enabled? Defaults to false"
  type        = bool
  default     = false
}

variable "enable_accelerated_networking" {
  description = "Should Accelerated Networking be enabled? Defaults to false."
  type        = bool
  default     = false
}

variable "internal_dns_name_label" {
  description = "The (relative) DNS Name used for internal communications between Virtual Machines in the same Virtual Network."
  type        = string
  default     = null
}

variable "private_ip_address_allocation_type" {
  description = "The allocation method used for the Private IP Address. Possible values are Dynamic and Static."
  type        = string
  default     = "Dynamic"
}

variable "private_ip_address" {
  description = "The Static IP Address which should be used. This is valid only when `private_ip_address_allocation` is set to `Static` "
  type        = string
  default     = null
}



variable "virtual_machine_name" {
  description = "The name of the virtual machine."
  type        = string
  default     = ""
}


variable "subnet_id" {
  description = "The resource ID of the subnet to attach the NIC to (from VNet module output, e.g. module.vnet.subnet_ids[\"public-az1\"])."
  type        = string
  default     = ""
}

variable "nsg_rules" {
  description = <<-EOT
    (Optional) Map of NSG rules to create and attach to the VM NIC.
    Omit or leave empty to skip NIC-level NSG (subnet NSG from VNet module applies).
    Each key becomes the rule name. Example:

    nsg_rules = {
      AllowSSH = {
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "10.0.0.0/8"
        destination_address_prefix = "*"
        description                = "Allow SSH from internal"
      }
    }
  EOT
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
  description = "(Optional) Resource ID of an existing NSG to attach to the VM NIC. Only used when nsg_rules is empty."
  type        = string
  default     = null
}

variable "virtual_machine_size" {
  description = "The Virtual Machine SKU for the Virtual Machine, Default is Standard_A2_V2"
  type        = string
  default     = "Standard_B2s"
}

variable "disable_password_authentication" {
  description = "Should Password Authentication be disabled on this Virtual Machine? Defaults to true."
  type        = bool
  default     = true
}

variable "admin_username" {
  description = "The username of the local administrator used for the Virtual Machine."
  type        = string
  default     = "azureuser"
}

variable "admin_password" {
  description = "The Password which should be used for the local-administrator on this Virtual Machine"
  type        = string
  default     = null
}

variable "source_image_id" {
  description = "The ID of an Image which each Virtual Machine should be based on"
  type        = string
  default     = null
}

variable "dedicated_host_id" {
  description = "The ID of a Dedicated Host where this machine should be run on."
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

variable "user_data" {
  description = "Raw (unencoded) user data for this Virtual Machine. The module handles base64 encoding."
  type        = string
  default     = null
}

variable "enable_encryption_at_host" {
  description = "Should all of the disks (including the temp disk) attached to this Virtual Machine be encrypted by enabling Encryption at Host?"
  type        = bool
  default     = false
}

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

variable "vm_availability_zone" {
  description = "The Zone in which this Virtual Machine should be created. Conflicts with availability set and shouldn't use both"
  type        = string
  default     = null
}


variable "generate_admin_ssh_key" {
  description = "Generates a secure private key and encodes it as PEM."
  type        = bool
  default     = true
}

variable "admin_ssh_key_data" {
  description = "specify the path to the existing SSH key to authenticate Linux virtual machine"
  type        = string
  default     = null
}

variable "custom_image" {
  description = "Provide the custom image to this module if the default variants are not sufficient"
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
  default = null
}

# ── Source image ─────────────────────────────────────────────────────────────
# Provide the four image fields directly in terraform.tfvars (or accept the
# defaults below, which resolve to Canonical Ubuntu 22.04 LTS).
# Reference: https://learn.microsoft.com/azure/virtual-machines/linux/cli-ps-findimage

variable "source_image_publisher" {
  description = "Publisher of the VM source image (e.g. Canonical, RedHat, OpenLogic)"
  type        = string
  default     = "Canonical"
}

variable "source_image_offer" {
  description = "Offer of the VM source image (e.g. ubuntu-22_04-lts)"
  type        = string
  default     = "ubuntu-22_04-lts"
}

variable "source_image_sku" {
  description = "SKU of the VM source image (e.g. server)"
  type        = string
  default     = "server"
}

variable "source_image_version" {
  description = "Version of the VM source image. Use 'latest' to always pick the newest patch."
  type        = string
  default     = "latest"
}


variable "os_disk_storage_account_type" {
  description = "The Type of Storage Account which should back this the Internal OS Disk. Possible values include Standard_LRS, StandardSSD_LRS and Premium_LRS."
  type        = string
  default     = "StandardSSD_LRS"
}

variable "os_disk_caching" {
  description = "The Type of Caching which should be used for the Internal OS Disk. Possible values are `None`, `ReadOnly` and `ReadWrite`"
  type        = string
  default     = "ReadWrite"
}

variable "disk_encryption_set_id" {
  description = "The ID of the Disk Encryption Set which should be used to Encrypt this OS Disk. The Disk Encryption Set must have the `Reader` Role Assignment scoped on the Key Vault - in addition to an Access Policy to the Key Vault"
  type        = string
  default     = null
}

variable "disk_size_gb" {
  description = "The Size of the Internal OS Disk in GB, if you wish to vary from the size used in the image this Virtual Machine is sourced from."
  type        = number
  default     = null
}

variable "enable_os_disk_write_accelerator" {
  description = "Should Write Accelerator be Enabled for this OS Disk? This requires that the `storage_account_type` is set to `Premium_LRS` and that `caching` is set to `None`."
  type        = bool
  default     = false
}

variable "os_disk_name" {
  description = "The name which should be used for the Internal OS Disk"
  type        = string
  default     = null
}

variable "enable_ultra_ssd_data_disk_storage_support" {
  description = "Should the capacity to enable Data Disks of the UltraSSD_LRS storage account type be supported on this Virtual Machine"
  type        = bool
  default     = false
}

variable "managed_identity_type" {
  description = "The type of Managed Identity which should be assigned to the Linux Virtual Machine. Possible values are `SystemAssigned`, `UserAssigned` and `SystemAssigned, UserAssigned`"
  type        = string
  default     = null
}

variable "managed_identity_ids" {
  description = "A list of User Managed Identity ID's which should be assigned to the Linux Virtual Machine."
  type        = list(string)
  default     = null
}

variable "enable_boot_diagnostics" {
  description = "Should the boot diagnostics enabled?"
  type        = bool
  default     = true
}

variable "data_disks" {
  description = "Managed Data Disks for azure virtual machine"
  type = list(object({
    name                 = string
    storage_account_type = string
    disk_size_gb         = number
  }))
  default = []
}


variable "create_storage_account" {
  description = "Create a dedicated storage account for boot diagnostics. Defaults to false – Azure managed boot diagnostics (storage_account_uri = null) is used instead."
  type        = bool
  default     = false
}

variable "storage_account_name" {
  description = "The name of the storage account used for storing virtual hard disks"
  type        = string
  default     = null
}

variable "storage_account_tier_type" {
  description = "The storage account tier (used only when creating a new storage account)"
  type        = string
  default     = "Standard"
}

variable "storage_account_replication_type" {
  description = "The type of replication for the storage account (used only when creating a new storage account)"
  type        = string
  default     = "ZRS"
}

variable "storage_account_resource_group_name" {
  description = "The resource group that contains the storage account"
  type        = string
  default     = null
}


variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "key_vault" {
  description = "Configuration for the Key Vault to store VM secrets"
  type        = any
  default     = null
}

variable "key_vault_purge_protection_enabled" {
  description = "Default for purge protection when not specified inside the key_vault object. Set true for production."
  type        = bool
  default     = true
}

variable "key_vault_soft_delete_retention_days" {
  description = "Default soft-delete retention days when not specified inside the key_vault object. Must be between 7 and 90."
  type        = number
  default     = 7
}

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
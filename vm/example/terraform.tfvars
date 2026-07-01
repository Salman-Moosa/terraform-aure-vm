# Reference values for a consumer root module. Assumes VNet/subnet already exist.
###############################################################################

# ─── Resource basics ──────────────────────────────────────────────────────────



resource_group_name = "infra-sandbox"


location = "UAE North"

virtual_machine_name = "vm-test-app"


# ─── Networking ───────────────────────────────────────────────────────────────
# Subnet resource ID — paste the output from the VNet module.
# e.g. if using modules: subnet_id = module.vnet.subnet_ids["public-az1"]

subnet_id = "/subscriptions/748797a3-ec14-4eb1-bffd-819c9a157541/resourceGroups/infra-sandbox/providers/Microsoft.Network/virtualNetworks/sandbox-vnet/subnets/public-az1"
# ─── Private IP ───────────────────────────────────────────────────────────────
# Default is Dynamic. Set to Static and provide an address if needed.

private_ip_address_allocation_type = "Dynamic"
# private_ip_address                 = "10.0.1.10" for static

# ─── Public IP (optional) ─────────────────────────────────────────────────────
# Set create_public_ip_address = true to attach a public IP to the VM NIC.

create_public_ip_address = true # by default false
# public_ip_allocation_method = "Static"
# public_ip_sku               = "Standard"

# ─── NIC-level NSG (optional) ─────────────────────────────────────────────────
# Option 1 — Create a new NSG with inline rules (fully named fields, stable map)
# Add/remove rules by changing the map and re-running terraform apply.
# Only the changed rule is created/destroyed; others are unaffected.
#
nsg_rules = {
  AllowSSH = {
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    description                = "Allow SSH from all networks"
  }
  AllowHTTPS = {
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    description                = "Allow HTTPS from anywhere"
  }
}

# Option 2 — Attach an existing NSG by resource ID (nsg_rules must be empty)
# existing_nsg_id = "/subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.Network/networkSecurityGroups/<name>"

# Option 3 — No NIC-level NSG (default)
# Leave both nsg_rules and existing_nsg_id unset.
# Traffic is governed by the subnet-level NSG from the VNet module.

# ─── VM Configuration ─────────────────────────────────────────────────────────

virtual_machine_size   = "Standard_B2s"
generate_admin_ssh_key = true

# Optional VM Configuration
# admin_username       = "azureuser"
# vm_availability_zone = "1"

# Secure boot (Trusted Launch) is on by default.
# It requires a Gen2 image. If you are using a Gen1 image, you MUST set both to false.
# enable_tpm         = true
# enable_secure_boot = true

# Option 1: Inline content
custom_data = {
  content = <<-EOF
    #!/bin/bash
    echo "Hello, World!" > /var/log/custom-data.txt
  EOF
}

# Option 2: Local file less than 64kb
# custom_data = {
#   file = "scripts/init.sh"
# }

# Option 3: No custom data
# custom_data = null

# ─── OS Image ─────────────────────────────────────────────────────────────────
# Ubuntu 22.04 LTS

source_image_publisher = "Canonical"
source_image_offer     = "ubuntu-22_04-lts"
source_image_sku       = "server"
source_image_version   = "latest"

# ─── OS Disk ──────────────────────────────────────────────────────────────────
# Check type for different workloads:
# Premium_LRS: Best for production and performance-sensitive workloads
# StandardSSD_LRS: Best for web servers, lightly used enterprise applications, and dev/test
# Standard_LRS: Best for backup, non-critical, and infrequent access


os_disk_storage_account_type = "StandardSSD_LRS"
os_disk_caching              = "ReadWrite"
disk_size_gb                 = 30

# ─── Boot Diagnostics ──────────────────────────────────────────────────────────────────
# Azure managed boot diagnostics: storage_account_uri is set to null inside
# the module, so Azure hosts the diagnostic blobs  – no storage
# account resource is created in your subscription.
# Set create_storage_account = true to bring your own storage account.

enable_boot_diagnostics = true
create_storage_account  = false

# ─── Data Disks (optional) ────────────────────────────────────────────────────────────
# Remove or leave empty to attach no extra disks.

data_disks = [
  # {
  #   name                 = "disk1"
  #   disk_size_gb         = 64
  #   storage_account_type = "StandardSSD_LRS"
  # },
]

# ─── Extensions (optional) ────────────────────────────────────────────────────────────
# Map of VM extensions to be installed.

extensions = {
  "CustomScript" = {
    publisher            = "Microsoft.Azure.Extensions"
    type                 = "CustomScript"
    type_handler_version = "2.1"
    settings = {
      "commandToExecute" = "echo 'Hello World' > /tmp/hello.txt"
    }
  }
  #   "OmsAgentForLinux" = {
  #     publisher            = "Microsoft.EnterpriseCloud.Monitoring"
  #     type                 = "OmsAgentForLinux"
  #     type_handler_version = "1.13"
  #     settings = {
  #       "workspaceId" = "your-workspace-id"
  #     }
  #     protected_settings = {
  #       "workspaceKey" = "your-workspace-key"
  #     }
  #   }
}

# ─── Key Vault – SSH key storage ──────────────────────────────────────────────
# When key_vault is set, the module will:
#   1. Create the Key Vault in the devops RG
#   2. Grant the deploying identity (pipeline SP / your user) Secrets Officer
#   3. Store the generated SSH private key as a secret automatically
#
# Requires generate_admin_ssh_key = true AND disable_password_authentication = true (both are true by default).

# key_vault = {
#   name                       = "kv-vm-test-app-dev" # must be globally unique, 3-24 chars
#   sku_name                   = "standard"
#   purge_protection_enabled   = false # set true for production
#   soft_delete_retention_days = 7

#   # ── Additional Secrets Officers (write access) ──────────────────────────
#   secret_officers = [
#     # { name = "my-team-sp", principal_id = "<object-id>" },
#     # { name = "devops-sandbox-admins", principal_id = "8eb5c0d8-484b-49eb-bbee-f91d3a02e8b0" }
#   ]

#   # ── Secrets Readers (read-only) ─────────────────────────────────────────
#   # secret_readers = [
#   #   { name = "app-identity", principal_id = "<object-id>" },
#   # ]
# }

# ─── Tags ─────────────────────────────────────────────────────────────────────

tags = {

  Environment          = "dev"
  Owner                = "stackgenie"
  ManagedBy            = "terraform"
  Service              = "linux-vm"
  Status               = "active"
  SourceCodeRepository = "infra"

}
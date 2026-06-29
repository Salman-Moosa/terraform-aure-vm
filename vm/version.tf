###############################################################################
# versions.tf – Azure module for VM
#
# Terraform and provider version constraints for the azure-vm module. 
###############################################################################

terraform {
  required_version = "~> 1.15.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.76"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.6.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 3.1.0"
    }

  }


}

# provider "azurerm" {
#   features {}
# }

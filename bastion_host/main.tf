# define terraform provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.97.1"
    }
  }

  required_version = ">= 0.14.9"
}

# Provider listing
provider "azurerm" {
  features {}
}

variable "remote_virtual_network_id" {
  description = "The ID of the remote Virtual Network from which to peer with this Virtual Network"
  type        = string
}


# Define a separate v-net for our bastion host
resource "azurerm_virtual_network" "bastion_vnet" {
  name                = "bastion-vnet"
  location            = "eastus"
  resource_group_name = "aks-platform-private-rg"
  address_space       = ["10.1.0.0/16"]
}

# Define the subnet for the bastion host
resource "azurerm_subnet" "bastion_subnet" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = "aks-platform-private-rg"
  virtual_network_name = azurerm_virtual_network.bastion_vnet.name
  address_prefixes     = ["10.1.0.0/24"]
}

# define the public ip for bastion
resource "azurerm_public_ip" "bastion_ip" {
    name                = "bastion-public-ip"
    location            = "eastus"
    resource_group_name = "aks-platform-private-rg"
    allocation_method   = "Static"
    sku                 = "Standard"

    lifecycle {
        ignore_changes = [
            tags
        ]
    }
}

# define azure bastion host
resource "azurerm_bastion_host" "bastion" {
    name                = "bastion-host"
    location            = "eastus"
    resource_group_name = "aks-platform-private-rg"
    ip_configuration {
        name                 = "bastion-ip-configuration"
        subnet_id            = azurerm_subnet.bastion_subnet.id
        public_ip_address_id = azurerm_public_ip.bastion_ip.id
    }

    lifecycle {
        ignore_changes = [
            tags
        ]
    }
}

# Peering our new V-NET with a Bastion Host to the AKS V-net
resource "azurerm_virtual_network_peering" "aks_to_bastion" {
    name                         = "aks-to-bastion"
    resource_group_name          = "aks-platform-private-rg"
    virtual_network_name         = "aks-private-vnet"
    remote_virtual_network_id    = azurerm_virtual_network.bastion_vnet.id
}

# Define the resource group peering of vnet to bastion
resource "azurerm_virtual_network_peering" "bastion_to_aks" {
    name                         = "bastion-to-aks"
    resource_group_name          = "aks-platform-private-rg"
    virtual_network_name         = azurerm_virtual_network.bastion_vnet.name
    remote_virtual_network_id    = var.remote_virtual_network_id
}
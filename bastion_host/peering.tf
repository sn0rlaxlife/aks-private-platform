# Generate Azure TF Main.tf for the Azure Terraform
# define terraform provider
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
  }

  required_version = ">= 0.14.9"
}
# Define the provider
provider "azurerm" {
  features {}
}


variable "vnet_bastion_name" {
    description = "The name of the virtual network"
    type        = string
}

variable "vnet_bastion_id" {
    description = "The ID of the virtual network"
    type        = string
}

variable "vnet_aks_name" {
    description = "Virtual Network Configuration defines subnet and CIDR for VNET"
    type = string
}

variable "vnet_aks_id" {
    description = "The ID of the virtual network from main.tf"
    type        = string
}

variable "resource_group_name" {
    description = "The name of the resource group"
    type        = string
    default     = "aks-platform-private-rg"
}

# Peering our new V-NET with a Bastion Host to the AKS V-net
# Peering from AKS VNet to Bastion VNet
resource "azurerm_virtual_network_peering" "aks_to_bastion" {
    name                         = "aks-to-bastion"
    resource_group_name          = var.resource_group_name
    virtual_network_name         = var.vnet_aks_name
    remote_virtual_network_id    = var.vnet_bastion_id  # Bastion VNet ID here
    allow_virtual_network_access = true
    allow_forwarded_traffic      = true
}

# Peering from Bastion VNet to AKS VNet
resource "azurerm_virtual_network_peering" "bastion_to_aks" {
    name                         = "bastion-to-aks"
    resource_group_name          = var.resource_group_name
    virtual_network_name         = var.vnet_bastion_name
    remote_virtual_network_id    = var.vnet_aks_id  # AKS VNet ID here
    allow_virtual_network_access = true
    allow_forwarded_traffic      = true
}
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

# Define the resource group
resource "azurerm_resource_group" "rg" {
  name     = "aks-platform-private-rg"
  location = "East US"
}

# Define the virtual network
resource "azurerm_virtual_network" "vnet" {
  name                = "aks-private-vnet"
  address_space       = [var.vnet.cidr_block]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}


# Define the subnet
resource "azurerm_subnet" "subnet" {
  name                 = "subnet-aks-private"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.vnet.subnet_cluster]
}

# Define the API Server VNET Integration in same network
resource "azurerm_subnet" "aks_subnet_network" {
  name                 = "aks-subnet-network"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.vnet.subnet_api_server]
}

# Define public IP to associate with NAT Gateway
resource "azurerm_public_ip" "public_ip" {
  name                = "public-ip-aks-native"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1"]
}


# Define the public IP Prefix
resource "azurerm_public_ip_prefix" "nat_prefix" {
  name                = "public-ip-aks-native"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  ip_version          = "IPv4"
  prefix_length       = 29
  sku                 = "Standard"
  zones               = ["1"]
}

# Define network gateway NAT
resource "azurerm_nat_gateway" "nat_aks" {
  name                    = "aks-native-gateway"
  location                = azurerm_resource_group.rg.location
  resource_group_name     = azurerm_resource_group.rg.name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 10
  zones                   = ["1"]
}

# Associate public ip with nat gateway that will communicate with AKS
resource "azurerm_nat_gateway_public_ip_association" "nat_gateway_public_ip" {
  nat_gateway_id       = azurerm_nat_gateway.nat_aks.id
  public_ip_address_id = azurerm_public_ip.public_ip.id
}


# Define NAT Gateway Public IP Prefix Association - NAT Gateway
resource "azurerm_nat_gateway_public_ip_prefix_association" "nat_ips" {
  nat_gateway_id      = azurerm_nat_gateway.nat_aks.id
  public_ip_prefix_id = azurerm_public_ip_prefix.nat_prefix.id
}

# Associate the azurerm_subnet_nat_gateway with the NAT Gateway
resource "azurerm_subnet_nat_gateway_association" "subnet_nat_gateway" {
  subnet_id      = azurerm_subnet.subnet.id
  nat_gateway_id = azurerm_nat_gateway.nat_aks.id
}

output "gateway_ips" {
  value = azurerm_public_ip_prefix.nat_prefix.ip_prefix
}

# Define the network security group
resource "azurerm_network_security_group" "nsg" {
  name                = "aks-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}


# Define the network security group rule
resource "azurerm_network_security_rule" "aks-subnet-to-bastion" {
  name                        = "AllowInbound"
  priority                    = 1001
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*" # Recommend to have this as * for all ports the destination port acts as filter range
  destination_port_range      = "443"
  source_address_prefix       = azurerm_subnet.subnet.address_prefixes[0]
  destination_address_prefix  = azurerm_subnet.bastion_host_subnet.address_prefixes[0]
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg.name
}
resource "azurerm_network_security_rule" "bastion_to_aks" {
  name                        = "AllowOutboundToAKS"
  priority                    = 1002
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = azurerm_subnet.bastion_host_subnet.address_prefixes[0]
  destination_address_prefix  = azurerm_subnet.subnet.address_prefixes[0]
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

resource "azurerm_network_security_rule" "aks_from_bastion" {
  name                        = "AllowInboundFromBastion"
  priority                    = 1003
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = azurerm_subnet.bastion_host_subnet.address_prefixes[0]
  destination_address_prefix  = azurerm_subnet.aks_subnet_network.address_prefixes[0]
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

# Associate with the subnet_network_security_group association with our bastion_host_subnet since this houses the machine
resource "azurerm_subnet_network_security_group_association" "bastion_nsg_association" {
  subnet_id                 = azurerm_subnet.bastion_host_subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# Associate the aks subnet with the network security group
resource "azurerm_subnet_network_security_group_association" "aks_nsg_association" {
  subnet_id                 = azurerm_subnet.aks_subnet_network.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}


# Define a separate v-net for our bastion host
resource "azurerm_virtual_network" "bastion_vnet" {
  name                = "bastion-vnet"
  location            = "eastus"
  resource_group_name = azurerm_resource_group.rg.name
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
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"

  lifecycle {
    ignore_changes = [
      tags
    ]
  }

  depends_on = [
    azurerm_resource_group.rg
  ]
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

resource "azurerm_subnet" "bastion_host_subnet" {
  name                 = "bastion-host-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.bastion_vnet.name
  address_prefixes     = ["10.1.1.0/24"]

  depends_on = [
    azurerm_virtual_network.bastion_vnet
  ]
}

resource "azurerm_network_interface" "bastion_host_nic" {
  name                = "bastion-host-nic"
  location            = "eastus"
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "bastion-host-ipconfig"
    subnet_id                     = azurerm_subnet.bastion_host_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
  depends_on = [
    azurerm_subnet.bastion_host_subnet
  ]

}


output "vnet_name_bastion" {
  value       = azurerm_virtual_network.bastion_vnet.name
  description = "The name of the bastion virtual network"
}

output "vnet_bastion_id" {
  value       = azurerm_virtual_network.bastion_vnet.id
  description = "The ID of the bastion virtual network"
}

output "vnet" {
  value       = azurerm_virtual_network.vnet.name
  description = "The name of the AKS virtual network"
}

output "vnet_id" {
  value       = azurerm_virtual_network.vnet.id
  description = "The ID of the AKS virtual network"
}

module "bastion_host" {
  source = "./bastion_host"

  resource_group_name = azurerm_resource_group.rg.name 
  vnet_bastion_name   = azurerm_virtual_network.bastion_vnet.name
  vnet_bastion_id     = azurerm_virtual_network.bastion_vnet.id
  vnet_aks_name       = azurerm_virtual_network.vnet.name
  vnet_aks_id         = azurerm_virtual_network.vnet.id
}


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
resource "azurerm_network_security_rule" "nsg-rule" {
  name                        = "AllowInbound"
  priority                    = 1001
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

module "bastion_host" {
  source = "./bastion_host"

  vnet_id = azurerm_virtual_network.vnet.id
}
variable "vnet" {
  description = "Virtual Network Configuration defines subnet and CIDR for VNET"
  type = object({
    cidr_block     = string
    subnet_cluster = string
    subnet_api_server = string
    location       = string
  })
  default = {
    cidr_block     = "10.240.0.0/16"
    subnet_cluster = "10.240.0.0/22"
    subnet_api_server = "10.240.4.0/22"
    location       = "eastus"
  }
}

variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
  default     = "aks-platform-private-rg"
}

# The name of the subnet for accessing API Server this will be peered with our Virtual Network for segmented access
variable "subnet_name" {
  description = "The name of the subnet for accessing API Server"
  type        = string
  default     = "aks-subnet-network"
}

# Subnet that houses the NAT Gateway for outbound access
variable "subnet_name_aks" {
  description = "The name of the subnet for accessing AKS"
  type        = string
  default     = "subnet-aks-private"
}

# Virtual Network Name of the AKS Cluster that has to be assigned for Network Contributor Role
variable "vnet_name" {
  description = "The Virtaul Network Name of the AKS Cluster that has to be assigned for Network Contributor Role"
  type        = string
  default     = "aks-private-vnet"
}

# Due to scoping of the assignment this will need to be required in a .tfvars (workaround for now - have this as .gitignore don't commit)
variable "subscription_id" {
  description = "The Azure Subscription ID"
  type        = string
}

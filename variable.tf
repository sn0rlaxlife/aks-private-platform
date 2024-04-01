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

variable "resource_group" {
  description = "The name of the resource group"
  type        = string
  default     = "aks-platform-private-rg"
}

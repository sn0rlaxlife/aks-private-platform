variable "vnet" {
  description = "Virtual Network Configuration defines subnet and CIDR for VNET"
  type = object({
    cidr_block     = string
    subnet_cluster = string
    location       = string
  })
  default = {
    cidr_block     = "10.240.0.0/16"
    subnet_cluster = "10.240.0.0/22"
    location       = "eastus"
  }
}
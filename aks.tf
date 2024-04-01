# Create AKS Cluster from resource group - Private Cluster
data "azurerm_kubernetes_service_versions" "current" {
  location        = "eastus"
  include_preview = true
}

# Path: aks.tf
resource "azurerm_user_assigned_identity" "aks" {
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  name                = "aks-identity"
}

data "azurerm_subscription" "current" {}

resource "azurerm_role_assignment" "aks_network_contributor" {
  scope                =   "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Network/virtualNetworks/${var.vnet_name}/subnets/${var.subnet_name}" 
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.aks.principal_id

}

# Define the AKS Cluster
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "platform-k8s"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  node_resource_group = "${azurerm_resource_group.rg.name}-aks"
  kubernetes_version  = data.azurerm_kubernetes_service_versions.current.latest_version

  dns_prefix                = "platform-k8s"
  private_cluster_enabled   = true
  workload_identity_enabled = true
  oidc_issuer_enabled       = true
  default_node_pool {
    name                = "default"
    node_count          = 1
    vm_size             = "Standard_D2_v2"
    zones               = ["1"]
    enable_auto_scaling = true
    min_count           = 1
    max_count           = 3
    vnet_subnet_id      = azurerm_subnet.subnet.id
  }
  api_server_access_profile {
    vnet_integration_enabled = true
    subnet_id                = azurerm_subnet.aks_subnet_network.id
  }

  identity {
    type = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aks.id]
  }
  network_profile {
    network_plugin    = "azure"
    network_policy    = "azure"
    dns_service_ip    = "172.16.0.10"
    service_cidr      = "172.16.0.0/16"
    load_balancer_sku = "standard"
    outbound_type     = "userAssignedNATGateway"

    nat_gateway_profile {
      idle_timeout_in_minutes = 4
    }
  }
  lifecycle {
    ignore_changes = [
      network_profile[0].nat_gateway_profile
    ]
  }
  depends_on = [
    azurerm_nat_gateway_public_ip_association.nat_gateway_public_ip
  ]
}

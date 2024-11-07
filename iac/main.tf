provider "azurerm" {
    features {}
}

# Variables for custom configuration 
variable "resource_group_name" {
    type = string
    default = "K8sProject"  
}

variable "location" {
    type = string
    default = "UKSouth"
}

variable "acr_name" {
    type = string
    default = "K8sACR" 
}

variable "aks_cluster_name" {
  type    = string
  default = "K8sCluster"
}

# Create Resource Group
resource "azurerm_resource_group" "main" {
    name = var.resource_group_name
    location = var.location 
}

# Create Azure Container Registry
resource "azurerm_container_registry" "main" {
    name = var.acr_name
    resource_group_name = azurerm_resource_group.main
    location = azurerm_resource_group.main.location
    sku = "Basic"
    admin_enabled = true
  
}

# Create AKS Cluster 
resource "azurerm_kubernetes_cluster" "main" {
  name                = var.aks_cluster_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = "aks"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_DS2_v2"
  }

  identity {
    type = "SystemAssigned"
  }

  depends_on = [azurerm_container_registry.main]
}

# Create Log Analytics Workspace for Monitoring
resource "azurerm_log_analytics_workspace" "main" {
    name = "${var.resource_group_name}-log"
    location = var.location
    resource_group_name = azurerm_resource_group.main.name
    sku = "PerGB2018"
    retention_in_days = 30
}


# Assign ACR Pull Role to AKS
resource "azurerm_role_assignment" "acr_pull" {
    principal_id = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
    role_definition_name = "AcrPull"
    scope = azurerm_container_registry.main.id
}
  

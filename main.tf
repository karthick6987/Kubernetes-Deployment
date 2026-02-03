# Add this at the top of main.tf
variable "docker_image" {
  type        = string
  description = "The docker image to deploy"
}

# --- 1. PROVIDER SETUP ---
terraform {
  required_providers {
    azurerm = { source = "hashicorp/azurerm", version = "~> 3.0" }
    kubernetes = { source = "hashicorp/kubernetes", version = "~> 2.0" }
  }
}

provider "azurerm" {
  features {}
}

# --- 2. THE AZURE HOUSE (AKS Cluster) ---
resource "azurerm_resource_group" "rg" {
  name     = "practice-devops-rg"
  location = "East US"
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "my-practice-aks"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "practiceaks"

  default_node_pool {
    name       = "default"
    node_count = 1        
    vm_size    = "Standard_B2s" 
  }

  identity { type = "SystemAssigned" }
}

# --- 3. THE BRIDGE (Connects Terraform to the new AKS) ---
provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.aks.kube_config.0.host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.cluster_ca_certificate)
}

# --- 4. THE FURNITURE (Your App) ---
resource "kubernetes_deployment" "webapp" {
  metadata { name = "my-web-app" }
  spec {
    replicas = 1
    selector { match_labels = { app = "webapp" } }
    template {
      metadata { labels = { app = "webapp" } }
      spec {
        container {
          # FIXED: Now using the variable passed from GitHub Actions
          image = var.docker_image 
          name  = "webapp-container"
          port { container_port = 80 }
        }
      }
    }
  }
}
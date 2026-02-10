# --- 1. VARIABLES ---
variable "docker_image" {
  type        = string
  description = "The docker image to deploy"
}

variable "env" {
  type        = string
  description = "The deployment environment (staging or prod)"
}

# --- 2. PROVIDER SETUP ---
terraform {
  required_providers {
    azurerm    = { source = "hashicorp/azurerm", version = "~> 3.0" }
    kubernetes = { source = "hashicorp/kubernetes", version = "~> 2.0" }
  }
  backend "azurerm" {}
  # We leave the backend block empty because we will provide the 
  # 'key' dynamically in the GitHub Action YAML
}

provider "azurerm" {
  features {}
}


# --- 3. THE AZURE HOUSE (Dynamic Names) ---
resource "azurerm_resource_group" "rg" {
  # Dynamic Name: practice-devops-staging-rg OR practice-devops-prod-rg
  name     = "practice-devops-${var.env}-rg"
  location = "East US"
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "my-practice-aks-${var.env}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "practiceaks${var.env}"

  # Custom node group name to avoid conflicts
  node_resource_group = "MC_infra_${var.env}"

  default_node_pool {
    name       = "default"
    # Logic: 1 node for staging to save money, 2 for prod for stability
    node_count = var.env == "prod" ? 2 : 1 
    vm_size    = "Standard_B2s" 
  }

  identity { type = "SystemAssigned" }
}

# --- 4. THE BRIDGE ---
provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.aks.kube_config.0.host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.cluster_ca_certificate)
}

# --- 5. THE FURNITURE (Your App) ---
resource "kubernetes_deployment" "webapp" {
  metadata { 
    name = "my-web-app-${var.env}" 
  }
  spec {
    replicas = var.env == "prod" ? 2 : 1
    selector { match_labels = { app = "webapp" } }
    template {
      metadata { labels = { app = "webapp" } }
      spec {
        container {
          image = var.docker_image 
          name  = "webapp-container"
          port { container_port = 80 }
        }
      }
    }
  }
}


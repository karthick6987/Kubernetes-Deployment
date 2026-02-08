resource "kubernetes_service" "webapp_service" {
  metadata { 
    # Dynamic name: webapp-service-staging or webapp-service-prod
    name = "webapp-service-${var.env}" 
  }
  spec {
    selector = { app = "webapp" }
    port {
      port        = 80
      target_port = 80
    }
    type = "LoadBalancer"
  }
}
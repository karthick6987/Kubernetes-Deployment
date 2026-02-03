resource "kubernetes_service" "webapp_service" {
  metadata {
    name = "webapp-service"
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
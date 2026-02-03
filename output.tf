# outputs.tf

output "public_ip" {
  description = "The public IP address of the web application"
  value       = kubernetes_service.webapp_service.status.0.load_balancer.0.ingress.0.ip
}
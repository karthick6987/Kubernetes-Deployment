output "public_ip" {
  description = "The public IP address of the web application"
  # Reference the service using the dynamic name we defined above
  value       = kubernetes_service.webapp_service.status.0.load_balancer.0.ingress.0.ip
}
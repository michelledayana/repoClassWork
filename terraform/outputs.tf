output "alb_url" {
  description = "URL del Load Balancer"
  value       = "http://${aws_lb.alb.dns_name}"
}

output "frontend_ip" {
  description = "IP pública del frontend"
  value       = aws_instance.frontend.public_ip
}

output "backend_ip" {
  description = "IP pública del backend"
  value       = aws_instance.backend.public_ip
}

output "db_private_ip" {
  description = "IP privada de la base de datos"
  value       = aws_instance.database.private_ip
}

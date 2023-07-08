output "Server-IP" {
  value = aws_instance.tower_instance.public_ip
}

output "fastapi_heartbeat_endpoint" {
  value = "http://${aws_instance.tower_instance.public_ip}/ping"
}

output "fastapi_docs_endpoint" {
  value = "http://${aws_instance.tower_instance.public_ip}/swagger"
}

output "instance_id" {
  description = "ID of the macOS EC2 instance"
  value       = aws_instance.macos.id
}

output "instance_public_ip" {
  description = "Public IP address of the macOS instance"
  value       = aws_instance.macos.public_ip
}

output "instance_private_ip" {
  description = "Private IP address of the macOS instance"
  value       = aws_instance.macos.private_ip
}

output "elastic_ip" {
  description = "Elastic IP address (if enabled)"
  value       = var.use_elastic_ip ? aws_eip.macos_eip[0].public_ip : null
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i ~/.ssh/cyrillic-ime-macos-key ec2-user@${var.use_elastic_ip ? aws_eip.macos_eip[0].public_ip : aws_instance.macos.public_ip}"
}

output "dedicated_host_id" {
  description = "ID of the dedicated host"
  value       = aws_ec2_host.macos_host.id
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.macos_sg.id
}

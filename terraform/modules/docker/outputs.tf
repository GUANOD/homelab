output "vm_id" {
  description = "Proxmox VM ID"
  value       = proxmox_virtual_environment_vm.docker.vm_id
}

output "ip_address" {
  description = "IPv4 address without prefix length"
  value       = split("/", var.address)[0]
}

output "admin_user" {
  description = "SSH user for Ansible"
  value       = var.admin_user
}

output "admin_private_key_path" {
  description = "Path of the generated SSH private key"
  value       = local_sensitive_file.admin_private_key.filename
}

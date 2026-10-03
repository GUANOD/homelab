output "ct_id" {
  description = "Proxmox container ID"
  value       = proxmox_virtual_environment_container.jellyfin.vm_id
}

output "ip_address" {
  description = "IPv4 address without prefix length"
  value       = split("/", var.address)[0]
}

output "root_private_key_path" {
  description = "Path of the generated root SSH private key"
  value       = local_sensitive_file.root_private_key.filename
}

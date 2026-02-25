output "container_id" {
  value = proxmox_virtual_environment_container.web_services.vm_id
}

output "instance_id" {
  description = "The ID of the provisioned virtual machine"
  value       = proxmox_virtual_environment_container.web_services.id
}

//root key
output "root_ws_public_key" {
  value = tls_private_key.root_ws_private_key.public_key_openssh
}
output "root_ws_private_key_path" {
  value = local_file.root_ws_private_key_file.filename
  sensitive = true
}

//admin key
output "admin_ws_public_key" {
  value = tls_private_key.admin_ws_private_key.public_key_openssh
}
output "admin_ws_private_key_path" {
  value = local_file.admin_ws_private_key_file.filename
  sensitive = true
}
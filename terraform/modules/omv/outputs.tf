output "omv_ip_address" {
  value = proxmox_virtual_environment_vm.omv_vm.id
}

output "root_omv_public_key" {
  value = tls_private_key.omv_key.public_key_openssh
  sensitive = true
}

output "root_omv_private_key_path" {
  value = local_file.private_key_file.filename
  sensitive = true
}
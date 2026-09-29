
output "admin_lbp_private_key_path" {
  value = local_file.root_lbp_private_key_file.filename
  sensitive = true
}
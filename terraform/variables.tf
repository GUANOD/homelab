//proxmox info
variable "pm_api_url" { type = string }
variable "pm_api_token_id" { type = string }
variable "pm_api_token_secret" { 
  type      = string
  sensitive = true 
}
// network
variable "network_gateway" { type = string }
//webservices
variable "webservices_password" {
  type = string
  sensitive = true
}
variable "webservices_address" { type = string}
variable "webservices_datastore" { type = string}
variable "webservices_datastoresize" { type = string}
variable "webservices_admin_user" { type = string }
variable "webservices_admin_password" { type = string }

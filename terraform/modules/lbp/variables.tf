variable "admin_user" { type = string }
# variable "address" { type = string}
variable "network_gateway" { type = string }
variable "password" { type = string }
variable "datastore" { type = string }
variable "datastoresize" { type = string }
variable "pm_api_url" { type = string }
variable "pm_user" { type = string }
variable "pm_user_password" {
  type      = string
  sensitive = true
}
variable "proxmox_node" {
  type    = string
  default = "pve1"
}

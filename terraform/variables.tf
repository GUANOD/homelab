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
  type      = string
  sensitive = true
}
variable "webservices_address" { type = string }
variable "webservices_datastore" { type = string }
variable "webservices_datastoresize" { type = string }
variable "webservices_admin_user" { type = string }
variable "webservices_admin_password" {
  type      = string
  sensitive = true
}
variable "omv_address" { type = string }
variable "privileged_user" { type = string }
variable "privileged_user_pw" {
  type      = string
  sensitive = true
}
variable "omv_admin_user" { type = string }
variable "omv_password" {
  type      = string
  sensitive = true
}
variable "omv_backups_user" {
  description = "OMV user with write access to the \"backups\" SMB share"
  type        = string
}
variable "omv_backups_password" {
  description = "Password of omv_backups_user"
  type        = string
  sensitive   = true
}
variable "pve_ssh_private_key_path" {
  description = "SSH private key for root@pve1 (provider snippet uploads, OMV disk passthrough)"
  type        = string
  default     = "~/.ssh/pve"
}
variable "docker_vm_id" {
  description = "Proxmox VM ID of the Docker host"
  type        = number
  default     = 104
}
variable "docker_address" {
  description = "Docker host IPv4 address in CIDR format"
  type        = string
  default     = "10.14.75.4/24"
}
variable "backup_retention" {
  description = "vzdump retention on the omv-backups storage"
  type = object({
    daily   = number
    weekly  = number
    monthly = number
  })
  default = { daily = 7, weekly = 4, monthly = 3 }
}
variable "omv_opt_disk_id" {
  type    = string
  default = null
}
variable "omv_opt_disk_size" {
  type    = string
  default = null
}

variable "omv_passthrough_disks" {
  type = list(object({
    id   = string
    size = number
  }))
  default = []
}

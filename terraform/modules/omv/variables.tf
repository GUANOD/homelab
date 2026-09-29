
variable "proxmox_node" {
  type    = string
  default = "pve1"
}

variable "vm_name" {
  type    = string
  default = "omv"
}

variable "admin_user" {
  type    = string
  default = "omvadmin"
}

variable "admin_password" {
  type      = string
  sensitive = true
}

variable "vm_ip" {
  type        = string
  description = "IP in CIDR format (e.g. 192.168.1.50/24)"
  default     = "dhcp"
}

variable "network_gateway" {
  type = string
}

variable "vm_datastore" {
  type    = string
  default = "local-lvm"
}

variable "passthrough_disks" {
  type = list(object({
    id   = string
    size = number
  }))
  default = []
}
variable "pve_ip" {
  type    = string
  default = "10.14.75.9"
}

variable "privileged_user" {
  type      = string
  default   = "root"
  sensitive = true
}

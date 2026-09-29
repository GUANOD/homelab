variable "proxmox_node" {
  description = "Proxmox node to create the VM on"
  type        = string
  default     = "pve1"
}

variable "vm_id" {
  description = "Proxmox VM ID"
  type        = number
}

variable "vm_name" {
  description = "VM name and hostname"
  type        = string
  default     = "docker"
}

variable "address" {
  description = "IPv4 address in CIDR format, e.g. 10.14.75.4/24"
  type        = string
}

variable "network_gateway" {
  description = "IPv4 gateway"
  type        = string
}

variable "admin_user" {
  description = "Cloud-init user (SSH key only, passwordless sudo); Ansible connects as this user"
  type        = string
  default     = "maindev"
}

variable "cores" {
  description = "vCPU cores"
  type        = number
  default     = 4
}

variable "memory" {
  description = "RAM in MB"
  type        = number
  default     = 8192
}

variable "disk_size" {
  description = "OS disk size in GB"
  type        = number
  default     = 64
}

variable "datastore" {
  description = "Datastore for the VM disk and cloud-init drive"
  type        = string
  default     = "local-lvm"
}

variable "debian_image_build" {
  description = "Debian 13 genericcloud build (directory under cloud.debian.org/images/cloud/trixie/)"
  type        = string
  default     = "20260914-2601"
}

variable "debian_image_sha512" {
  description = "sha512 of the image, from that build's SHA512SUMS"
  type        = string
  default     = "95e110dfcdbd0ed8a82a75ed9579802f9950cabf51a810dcc6388e81bc778188713878b9f28d583a0ea602fbf48b35996ae9ad37f584166d8fbd6489df248f53"
}

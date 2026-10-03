variable "proxmox_node" {
  description = "Proxmox node to create the container on"
  type        = string
  default     = "pve1"
}

variable "ct_id" {
  description = "Proxmox container ID"
  type        = number
}

variable "hostname" {
  description = "Container hostname"
  type        = string
  default     = "jellyfin"
}

variable "address" {
  description = "IPv4 address in CIDR format, e.g. 10.14.75.15/24"
  type        = string
}

variable "network_gateway" {
  description = "IPv4 gateway"
  type        = string
}

variable "template_file_id" {
  description = "LXC template volume ID (local:vztmpl/...)"
  type        = string
}

variable "cores" {
  description = "CPU cores"
  type        = number
  default     = 4
}

variable "memory" {
  description = "RAM in MB"
  type        = number
  default     = 4096
}

variable "disk_size" {
  description = "Root disk size in GB (Jellyfin metadata, artwork, transcode cache)"
  type        = number
  default     = 32
}

variable "datastore" {
  description = "Datastore for the root disk"
  type        = string
  default     = "local-lvm"
}

variable "media_host_path" {
  description = "Host path of the media share (PVE storage jellyfinmedia, created by ansible/pve), bind-mounted at /media"
  type        = string
  default     = "/mnt/pve/jellyfinmedia"
}

variable "render_device" {
  description = "Host iGPU render node passed through for hardware transcoding"
  type        = string
  default     = "/dev/dri/renderD128"
}

variable "jellyfin_gid" {
  description = "gid of the jellyfin group inside the container (fixed by ansible/jellyfin); owns the render node"
  type        = number
  default     = 1000
}

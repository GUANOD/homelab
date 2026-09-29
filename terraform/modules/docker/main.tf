terraform {
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
    }
  }
}

# Admin SSH key (no password login on this VM)
resource "tls_private_key" "admin" {
  algorithm = "ED25519"
}

resource "local_sensitive_file" "admin_private_key" {
  content         = tls_private_key.admin.private_key_openssh
  filename        = pathexpand("~/.ssh/docker_admin_key")
  file_permission = "0600"
}

# Pinned Debian cloud image (dated build + checksum), own file so the OMV module isn't touched
resource "proxmox_virtual_environment_download_file" "debian_cloud_image" {
  content_type       = "import"
  datastore_id       = "local"
  node_name          = var.proxmox_node
  url                = "https://cloud.debian.org/images/cloud/trixie/${var.debian_image_build}/debian-13-genericcloud-amd64-${var.debian_image_build}.qcow2"
  file_name          = "debian-13-genericcloud-amd64-${var.debian_image_build}.qcow2"
  checksum           = var.debian_image_sha512
  checksum_algorithm = "sha512"
  overwrite          = false
}

# The genericcloud image has no guest agent; the provider waits for it to report IPs
resource "proxmox_virtual_environment_file" "vendor_data" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = var.proxmox_node

  source_raw {
    data      = <<-EOT
      #cloud-config
      package_update: true
      packages:
        - qemu-guest-agent
      runcmd:
        - systemctl enable --now qemu-guest-agent
    EOT
    file_name = "${var.vm_name}-vendor.yaml"
  }
}

resource "proxmox_virtual_environment_vm" "docker" {
  name        = var.vm_name
  node_name   = var.proxmox_node
  vm_id       = var.vm_id
  description = "Docker host (Portainer, Homepage). Managed by Terraform"
  tags        = ["debian", "docker", "terraform"]
  on_boot     = true

  scsi_hardware = "virtio-scsi-single"

  agent {
    enabled = true
  }

  cpu {
    cores = var.cores
    type  = "host"
  }

  memory {
    dedicated = var.memory
  }

  network_device {
    bridge = "vmbr0"
  }

  operating_system {
    type = "l26"
  }

  disk {
    datastore_id = var.datastore
    import_from  = proxmox_virtual_environment_download_file.debian_cloud_image.id
    interface    = "scsi0"
    iothread     = true
    discard      = "on"
    ssd          = true
    size         = var.disk_size
  }

  initialization {
    datastore_id = var.datastore

    ip_config {
      ipv4 {
        address = var.address
        gateway = var.network_gateway
      }
    }

    user_account {
      username = var.admin_user
      keys     = [trimspace(tls_private_key.admin.public_key_openssh)]
    }

    vendor_data_file_id = proxmox_virtual_environment_file.vendor_data.id
  }

  # Base image only matters at first boot; bumping it must not rebuild the VM
  lifecycle {
    ignore_changes = [disk[0].import_from]
  }
}

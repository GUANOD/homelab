terraform {
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
    }
  }
}

# Root SSH key for Ansible (no password login)
resource "tls_private_key" "root" {
  algorithm = "ED25519"
}

resource "local_sensitive_file" "root_private_key" {
  content         = tls_private_key.root.private_key_openssh
  filename        = pathexpand("~/.ssh/jellyfin_root_key")
  file_permission = "0600"
}

# Device passthrough and bind mounts are root@pam-only in PVE (API tokens are refused),
# so the caller passes the root@pam provider for this module
resource "proxmox_virtual_environment_container" "jellyfin" {
  node_name     = var.proxmox_node
  vm_id         = var.ct_id
  description   = "Jellyfin media server (iGPU transcoding, media from OMV). Managed by Terraform"
  tags          = ["debian", "jellyfin", "terraform"]
  unprivileged  = true
  start_on_boot = true

  features {
    nesting = true
  }

  cpu {
    cores = var.cores
  }

  memory {
    dedicated = var.memory
  }

  initialization {
    hostname = var.hostname

    ip_config {
      ipv4 {
        address = var.address
        gateway = var.network_gateway
      }
    }

    user_account {
      keys = [trimspace(tls_private_key.root.public_key_openssh)]
    }
  }

  network_interface {
    name   = "eth0"
    bridge = "vmbr0"
  }

  operating_system {
    template_file_id = var.template_file_id
    type             = "debian"
  }

  disk {
    datastore_id = var.datastore
    size         = var.disk_size
  }

  # iGPU render node, owned by the jellyfin group inside the container
  device_passthrough {
    path = var.render_device
    gid  = var.jellyfin_gid
    mode = "0660"
  }

  # Bind mount: not included in vzdump backups (media lives on OMV)
  mount_point {
    volume = var.media_host_path
    path   = "/media"
  }
}

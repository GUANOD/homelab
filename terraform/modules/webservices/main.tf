terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
    }
  }
}

resource "tls_private_key" "root_ws_private_key" {
  algorithm = "ED25519"
}

resource "local_file" "root_ws_private_key_file" {
  content  = tls_private_key.root_ws_private_key.private_key_openssh
  filename = pathexpand("~/.ssh/wsrootkey")
  file_permission = "0600"
}

resource "tls_private_key" "admin_ws_private_key" {
  algorithm = "ED25519"
}

resource "local_file" "admin_ws_private_key_file" {
  content  = tls_private_key.admin_ws_private_key.private_key_openssh
  filename = pathexpand("~/.ssh/wsadminkey")
  file_permission = "0600"
}

resource "proxmox_virtual_environment_container" "web_services" {
  node_name = "pve1"
  description = "Managed by Terraform"

  unprivileged = true
  features {
    nesting = true
  }

  initialization {
    hostname = "webservices"
    ip_config {
      ipv4 {
        address = var.address
        gateway = var.network_gateway
      }
    }
    
    user_account {
      keys     = [trimspace(tls_private_key.root_ws_private_key.public_key_openssh)]
      password = var.password
    }
  }

  network_interface {
    name = "eth0"
    bridge = "vmbr0"
  }

  operating_system {
    template_file_id = "local:vztmpl/debian-12-standard_12.12-1_amd64.tar.zst"
    type             = "debian"
  }

  disk {
    datastore_id = var.datastore
    size         = var.datastoresize
  }
}


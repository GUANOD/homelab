terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
    }
  }
}

//priviledged user required for usb passthrough 
provider "proxmox" {
  endpoint = var.pm_api_url
  password = var.pm_user_password
  username = var.pm_user
  insecure = true
}

resource "tls_private_key" "root_lbp_private_key" {
  algorithm = "ED25519"
}

resource "local_file" "root_lbp_private_key_file" {
  content  = tls_private_key.root_lbp_private_key.private_key_openssh
  filename = pathexpand("~/.ssh/lbprootkey")
  file_permission = "0600"
}

resource "proxmox_virtual_environment_container" "lbp" {
    node_name = var.proxmox_node

    unprivileged = false
    features {
        nesting = true
    }

    initialization {
        hostname = "lbp"
        ip_config {
            ipv4 {
                address = "dhcp"
                gateway = var.network_gateway
            }
        }
        
        user_account {
            keys     = [trimspace(tls_private_key.root_lbp_private_key.public_key_openssh)]
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

    memory {
      dedicated = 1024
    }
  # --- USB Printer Passthrough ---
#   device_passthrough {
#     path = "/dev/canon_printer"
#     mode = "0666" # Allows the container to read/write to the printer
#     uid  = 0      # Root inside container
#     gid  = 7      # 'lp' group in Debian
#   }

    device_passthrough {
        path = "/dev/bus/usb/001/004" 
    }
    
}
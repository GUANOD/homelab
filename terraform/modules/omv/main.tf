terraform {
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
    }
  }
}

# 1. SSH Key Generation
resource "tls_private_key" "omv_key" {
  algorithm = "ED25519"
}

resource "local_file" "private_key_file" {
  content         = tls_private_key.omv_key.private_key_openssh
  filename        = pathexpand("~/.ssh/omv_admin_key")
  file_permission = "0600"
}


resource "proxmox_virtual_environment_download_file" "debian_cloud_image" {
  content_type = "iso"
  datastore_id = "local"
  node_name    = var.proxmox_node
  url          = "https://cloud.debian.org/images/cloud/trixie/latest/debian-13-genericcloud-amd64.qcow2"
  file_name    = "debian-13-cloud.img"
  # "latest" changes upstream; don't re-download (and cascade a VM rebuild) on every plan
  overwrite    = false
}

resource "proxmox_virtual_environment_file" "omv_cloud_config" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = var.proxmox_node

  source_raw {
    data = templatefile("${path.module}/cloud-init.yaml", {
      hostname = var.vm_name
      username = var.admin_user
      password = bcrypt(var.admin_password)
      ssh_key  = trimspace(tls_private_key.omv_key.public_key_openssh)
      timezone = "UTC+1"
    })
    file_name = "omv-install.yaml"
  }

  # bcrypt() salts randomly, so the rendered data differs on every plan
  lifecycle {
    ignore_changes = [source_raw]
  }
}

# 3. Create the VM
resource "proxmox_virtual_environment_vm" "omv_vm" {
  depends_on = [proxmox_virtual_environment_file.omv_cloud_config, proxmox_virtual_environment_download_file.debian_cloud_image]

  name      = var.vm_name
  node_name = var.proxmox_node

  description = "OMV 7/8 installed on Debian 12 via Terraform"
  tags        = ["debian", "omv", "terraform"]

  cpu {
    cores = 2
    type  = "host"
  }

  memory {
    dedicated = 4096
  }

  network_device {
    bridge = "vmbr0"
  }

  operating_system {
    type = "l26"
  }

  agent {
    enabled = true
  }

  # OS Disk using the Cloud Image
  disk {
    datastore_id = var.vm_datastore
    file_id      = proxmox_virtual_environment_download_file.debian_cloud_image.id
    interface    = "virtio0"
    iothread     = true
    discard      = "on"
    size         = 20
  }

  initialization {

    ip_config {
      ipv4 {
        address = var.vm_ip
        gateway = var.network_gateway
      }
    }

    user_data_file_id = proxmox_virtual_environment_file.omv_cloud_config.id
  }

  # Base image and cloud-init only apply at first boot; never rebuild the VM for them
  lifecycle {
    ignore_changes = [disk[0].file_id, initialization[0].user_data_file_id]
  }
}

resource "null_resource" "attach_omv_storage" {

  for_each = { for i, disk in var.passthrough_disks : disk.id => {
    index = i + 1
    id    = disk.id
  } }

  triggers = {
    vm_id        = proxmox_virtual_environment_vm.omv_vm.vm_id
    partition_id = "${each.value.id}"
    scsi_slot    = "scsi${each.value.index}"
    pve_ip       = var.pve_ip
    user         = var.privileged_user
  }

  connection {
    type        = "ssh"
    user        = self.triggers.user
    private_key = file("~/.ssh/pve")
    host        = self.triggers.pve_ip
  }

  provisioner "remote-exec" {
    inline = [
      "qm set ${proxmox_virtual_environment_vm.omv_vm.vm_id} -${self.triggers.scsi_slot} ${each.value.id}"
    ]
  }

  provisioner "remote-exec" {
    when = destroy
    inline = [
      "qm set ${self.triggers.vm_id} --delete ${self.triggers.scsi_slot} || true"
    ]
  }

  depends_on = [proxmox_virtual_environment_vm.omv_vm]
}

resource "null_resource" "wait_for_omv" {

  triggers = {
    vm_id = proxmox_virtual_environment_vm.omv_vm.id
  }

  connection {
    type        = "ssh"
    user        = var.admin_user
    private_key = tls_private_key.omv_key.private_key_pem
    host        = split("/", var.vm_ip)[0]
  }

  provisioner "remote-exec" {
    inline = [
      # This loop waits until the file /tmp/cloud-config.done exists
      "while [ ! -f /tmp/cloud-config.done ]; do echo 'Waiting for OMV install...'; sleep 10; done",
      "echo 'OMV Install Complete!'"
    ]
  }

  depends_on = [null_resource.attach_omv_storage]
}

terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.96.0"
    }
  }
}

provider "proxmox" {
  endpoint = var.pm_api_url
  api_token = "${var.pm_api_token_id}=${var.pm_api_token_secret}"
  insecure  = true
}

module "webservices" {
  source           = "./modules/webservices"
  network_gateway  = var.network_gateway
  password = var.webservices_password
  address = var.webservices_address
  datastore = var.webservices_datastore
  datastoresize = var.webservices_datastoresize
  admin_user = var.webservices_admin_user
  admin_password = var.webservices_admin_password
  inventory_path = local_file.ansible_inventory.filename
}

resource "local_file" "ansible_inventory" {
  content = <<EOT
    [webservices]
    ${split("/", var.webservices_address )[0]} ansible_user=root ansible_ssh_private_key_file=${module.webservices.root_ws_private_key_path}
  EOT
  filename = "${path.module}/../ansible/inventory.ini"
}

resource "local_file" "ansible_vars" {
  content  = <<EOT
    admin_user: "${var.webservices_admin_user}"
    password: "${var.webservices_admin_password}"
    admin_public_key: "${module.webservices.admin_ws_public_key}"
    EOT
  filename = "../ansible/webservices/vars/tf_gen.yml"
}

resource "null_resource" "ansible_provisioner" {
  # Trigger when the instance changes
  triggers = {
    instance_id = module.webservices.instance_id
  }

    provisioner "local-exec" {
    environment = {
      ANSIBLE_HOST_KEY_CHECKING = "False"
    }
    command = "ansible-playbook -i ${local_file.ansible_inventory.filename} -e '@${local_file.ansible_vars.filename}' ${path.module}/../ansible/webservices/webservices.yml"
  }
}

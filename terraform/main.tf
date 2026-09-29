terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.96.0"
    }
  }
}

provider "proxmox" {
  endpoint  = var.pm_api_url
  api_token = "${var.pm_api_token_id}=${var.pm_api_token_secret}"
  insecure  = true

  # SSH is needed for snippet uploads; use the key file so runs don't depend on an ssh-agent
  ssh {
    agent       = false
    username    = "root"
    private_key = file(pathexpand(var.pve_ssh_private_key_path))
  }
}

module "webservices" {
  source          = "./modules/webservices"
  network_gateway = var.network_gateway
  password        = var.webservices_password
  address         = var.webservices_address
  datastore       = var.webservices_datastore
  datastoresize   = var.webservices_datastoresize
  admin_user      = var.webservices_admin_user
  admin_password  = var.webservices_admin_password
  inventory_path  = local_file.ansible_inventory.filename
}

module "omv" {
  source            = "./modules/omv"
  proxmox_node      = "pve1"
  admin_user        = var.omv_admin_user
  admin_password    = var.omv_password
  vm_ip             = var.omv_address
  network_gateway   = var.network_gateway
  passthrough_disks = var.omv_passthrough_disks
  privileged_user   = var.privileged_user
}

# PVE storage on the OMV "backups" SMB share (share itself is configured in OMV, not here yet)
resource "proxmox_virtual_environment_storage_cifs" "omv_backups" {
  depends_on = [module.omv]

  id       = "omv-backups"
  nodes    = ["pve1"]
  server   = split("/", var.omv_address)[0]
  share    = "backups"
  username = var.omv_backups_user
  password = var.omv_backups_password
  content  = ["backup"]

  backups {
    keep_daily   = var.backup_retention.daily
    keep_weekly  = var.backup_retention.weekly
    keep_monthly = var.backup_retention.monthly
  }
}

module "docker" {
  source          = "./modules/docker"
  vm_id           = var.docker_vm_id
  address         = var.docker_address
  network_gateway = var.network_gateway
}

# Read-only Proxmox API access for the Homepage dashboard widget
resource "proxmox_virtual_environment_user" "homepage" {
  user_id = "homepage@pve"
  comment = "Homepage dashboard (read-only). Managed by Terraform"

  # Permissions are managed by proxmox_virtual_environment_acl.homepage; without this the two fight every apply
  lifecycle {
    ignore_changes = [acl]
  }
}

resource "proxmox_virtual_environment_acl" "homepage" {
  user_id = proxmox_virtual_environment_user.homepage.user_id
  path    = "/"
  role_id = "PVEAuditor"
}

resource "proxmox_virtual_environment_user_token" "homepage" {
  user_id               = proxmox_virtual_environment_user.homepage.user_id
  token_name            = "homepage"
  comment               = "Homepage dashboard (read-only). Managed by Terraform"
  privileges_separation = false
}

# module "lbp" {
#   source = "./modules/lbp" 
#   network_gateway  = var.network_gateway
#   password = var.webservices_password
#   admin_user = var.webservices_admin_user
#   datastore = var.webservices_datastore
#   datastoresize = var.webservices_datastoresize
#   pm_api_url = var.pm_api_url
#   pm_user = var.privileged_user
#   pm_user_password = var.privileged_user_pw
# }

resource "local_file" "ansible_inventory" {
  content  = <<EOT
    [webservices]
    ${split("/", var.webservices_address)[0]} ansible_user=root ansible_ssh_private_key_file=${module.webservices.root_ws_private_key_path}
    [omv]
    ${split("/", var.omv_address)[0]} ansible_user=root ansible_ssh_private_key_file=${module.omv.root_omv_private_key_path}
    [docker]
    ${module.docker.ip_address} ansible_user=${module.docker.admin_user} ansible_become=true ansible_ssh_private_key_file=${module.docker.admin_private_key_path}
  EOT
  filename = "${path.module}/../ansible/inventory.ini"
}

resource "local_sensitive_file" "ansible_vars" {
  content         = <<-EOT
    admin_user: "${var.webservices_admin_user}"
    password: "${var.webservices_admin_password}"
    admin_public_key: "${module.webservices.admin_ws_public_key}"
    docker_address: "${module.docker.ip_address}"
    EOT
  filename        = "${path.module}/../ansible/webservices/vars/tf_gen.yml"
  file_permission = "0600"
}

resource "local_sensitive_file" "docker_ansible_vars" {
  content         = <<-EOT
    homepage_proxmox_token_id: "${proxmox_virtual_environment_user_token.homepage.id}"
    homepage_proxmox_token_secret: "${element(split("=", proxmox_virtual_environment_user_token.homepage.value), length(split("=", proxmox_virtual_environment_user_token.homepage.value)) - 1)}"
    EOT
  filename        = "${path.module}/../ansible/docker/vars/tf_gen.yml"
  file_permission = "0600"
}

# Re-runs when the VM is recreated or the playbook/templates/versions change
resource "null_resource" "docker_provisioner" {
  triggers = {
    vm_id = module.docker.vm_id
    # tf_gen.yml is written by this apply itself, so it must not feed the trigger
    playbook = sha1(join("", [for f in sort(fileset("${path.module}/../ansible/docker", "**/*.{yml,j2}")) : filesha1("${path.module}/../ansible/docker/${f}") if f != "vars/tf_gen.yml"]))
  }

  provisioner "local-exec" {
    environment = {
      # trust on first use, fail if the key later changes
      ANSIBLE_SSH_COMMON_ARGS = "-o StrictHostKeyChecking=accept-new"
    }
    command = "ansible-playbook -i ${local_file.ansible_inventory.filename} ${path.module}/../ansible/docker/docker.yml"
  }

  depends_on = [local_sensitive_file.docker_ansible_vars]
}

# Caddy routes run last: they point at every backend, so they wait for all guests to be configured.
# Re-runs when the routes playbook/template, the Caddy secrets or a backend address change.
resource "null_resource" "caddy_routes" {
  triggers = {
    routes = sha1(join("", [
      filesha1("${path.module}/../ansible/webservices/caddy.yml"),
      filesha1("${path.module}/../ansible/webservices/templates/Caddyfile.j2"),
      filesha1("${path.module}/../ansible/webservices/vars/secrets.yml"),
    ]))
    docker_address = module.docker.ip_address
  }

  provisioner "local-exec" {
    environment = {
      ANSIBLE_SSH_COMMON_ARGS = "-o StrictHostKeyChecking=accept-new"
    }
    command = "ansible-playbook -i ${local_file.ansible_inventory.filename} ${path.module}/../ansible/webservices/caddy.yml"
  }

  depends_on = [
    null_resource.ansible_provisioner,
    null_resource.docker_provisioner,
    local_sensitive_file.ansible_vars,
  ]
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
    command = "ansible-playbook -i ${local_file.ansible_inventory.filename} -e '@${local_sensitive_file.ansible_vars.filename}' ${path.module}/../ansible/webservices/webservices.yml"
  }
}

variable "network_gateway"  { type = string }
variable "password" { type = string }
variable "address" { type = string}
variable "datastore" { type = string }
variable "datastoresize" { type = string }
variable "admin_user"{
    type = string
    default = "maindev"
}
variable "admin_password" {
  type = string
#   sensitive = true
}
variable "inventory_path" { type = string }

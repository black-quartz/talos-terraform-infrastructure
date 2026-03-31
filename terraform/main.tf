###############################
##### Talos Cluster Nodes ##### 
###############################
locals {
  cluster_endpoint = "https://${var.cluster_endpoint}:6443"
}

resource "talos_machine_secrets" "this" {
  talos_version = var.talos_version

  lifecycle {
    prevent_destroy = true
  }
}

data "talos_client_configuration" "this" {
  cluster_name         = var.cluster_name
  client_configuration = talos_machine_secrets.this.client_configuration
  nodes = concat(
    [var.cluster_endpoint],
    keys(local.control_plane_nodes)
  )
}

data "talos_machine_configuration" "control_plane" {
  for_each = local.control_plane_nodes

  cluster_name     = var.cluster_name
  cluster_endpoint = local.cluster_endpoint
  
  machine_type    = "controlplane"
  machine_secrets = talos_machine_secrets.this.machine_secrets

  talos_version = var.talos_version
  
  config_patches = [
    local.talos_image_patch,
    local.cluster_patch,
    local.cluster_identity_patch,
    local.control_plane_patch,
    local.control_plane_node_patches[each.key]
  ]
}

resource "talos_machine_configuration_apply" "control_plane" {
  for_each = local.control_plane_nodes

  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.control_plane[each.key].machine_configuration
  node                        = each.value.metadata.address

  lifecycle {
    prevent_destroy = true
    precondition {
      condition     = talos_machine_secrets.this.machine_secrets != null
      error_message = "Machine secrets must be imported before applying node config." 
    }
  }
}

##################################
### Cluster Bootstrap Services ###
##################################

### Cilium ###
module "cilium" {
  source = "./modules/cilium"

  release_name   = "cilium"
  cilium_version = "1.19.1" 

  depends_on = [ talos_machine_configuration_apply.control_plane ]
}

### Longhorn ###
module "longhorn" {
  source = "./modules/longhorn"

  kubernetes_host        = local.cluster_endpoint
  cluster_ca_certificate = data.talos_client_configuration.this.client_configuration.ca_certificate
  client_certificate     = data.talos_client_configuration.this.client_configuration.client_certificate
  client_key             = data.talos_client_configuration.this.client_configuration.client_key 

  longhorn_default_data_path = "/var/lib/longhorn/data-1"

  depends_on = [ module.cilium ]
}

### Flux Operator ###
module "flux" {
  source = "./modules/flux"

  kubernetes_host        = local.cluster_endpoint
  cluster_ca_certificate = data.talos_client_configuration.this.client_configuration.ca_certificate
  client_certificate     = data.talos_client_configuration.this.client_configuration.client_certificate
  client_key             = data.talos_client_configuration.this.client_configuration.client_key 

  github_app_id              = var.flux_github_app_id
  github_app_installation_id = var.flux_github_app_installation_id
  github_app_pem             = var.flux_github_app_pem 

  git_url  = "https://github.com/black-quartz/flux-fleet-management.git"
  git_ref  = "refs/heads/main"
  git_path = "kubernetes/production"

  depends_on = [ module.cilium ]
}
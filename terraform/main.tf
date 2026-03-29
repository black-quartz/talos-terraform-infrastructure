###############################
##### Talos Cluster Nodes ##### 
###############################

resource "talos_machine_secrets" "this" {
  talos_version = var.talos_version

  lifecycle {
    prevent_destroy = true
  }
}

data "talos_machine_configuration" "control_plane" {
  for_each = local.control_plane_nodes

  cluster_name     = var.cluster_name
  cluster_endpoint = "https://${var.cluster_endpoint}:6443"
  
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

data "talos_client_configuration" "this" {
  cluster_name         = var.cluster_name
  client_configuration = talos_machine_secrets.this.client_configuration
  nodes = concat(
    [var.cluster_endpoint],
    keys(local.control_plane_nodes)
  )
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
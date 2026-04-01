###############################
##### Talos Cluster Nodes ##### 
###############################
locals {
  cluster_endpoint_uri = "https://${var.cluster_endpoint}:6443"
}

resource "talos_machine_secrets" "this" {}

data "talos_client_configuration" "this" {
  cluster_name         = var.cluster_name
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoints            = concat([var.cluster_endpoint], [for k, v in var.node_data.controlplanes : v.address])
}

data "talos_machine_configuration" "controlplane" {
  cluster_name     = var.cluster_name
  cluster_endpoint = local.cluster_endpoint_uri
  machine_type     = "controlplane"
  machine_secrets  = talos_machine_secrets.this.machine_secrets
}

resource "talos_machine_configuration_apply" "controlplane" {
  for_each = var.node_data.controlplanes

  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.controlplane.machine_configuration
  node                        = each.value.address

  config_patches = [
    file("${path.module}/nodes/controlplane/${each.key}.yml"),
    file("${path.module}/files/cluster-network.yml"),
    file("${path.module}/files/controlplane-scheduling.yml"),
    file("${path.module}/files/kernel-modules.yml"),
    file("${path.module}/files/kube-proxy.yml"),
    file("${path.module}/files/time-servers.yml"),
    templatefile("${path.module}/templates/hostname-config.yml.tftpl", {
      hostname = each.value.hostname
    }),
    templatefile("${path.module}/templates/install-image.yml.tftpl", {
      install_image = data.talos_image_factory_urls.base.urls.installer
    })
  ]
}
resource "talos_machine_bootstrap" "this" {
  depends_on = [talos_machine_configuration_apply.controlplane]

  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = [for k, v in var.node_data.controlplanes : v.address][0]
}

resource "talos_cluster_kubeconfig" "this" {
  depends_on = [talos_machine_bootstrap.this]
  
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = [for k, v in var.node_data.controlplanes : v.address][0]
}

##################################
### Cluster Bootstrap Services ###
##################################

resource "time_sleep" "after_bootstrap" {
  depends_on = [talos_machine_bootstrap.this]

  create_duration = "60s"
}

### Cilium ###
module "cilium" {
  depends_on = [talos_machine_configuration_apply.controlplane]
  
  source = "./modules/cilium"
  providers = {
    helm = helm
  }

  cilium_version = "1.19.1" 
}

### Longhorn ###
module "longhorn" {
  depends_on = [module.cilium]
  
  source = "./modules/longhorn"

  providers = {
    helm       = helm
    kubernetes = kubernetes
  }

  longhorn_default_data_path = "/var/lib/longhorn/data-1"
}

### Flux Operator ###
module "flux" {
  depends_on = [module.cilium]
  
  source = "./modules/flux"

  providers = {
    helm       = helm
    kubernetes = kubernetes
  }

  github_app_id              = var.flux_github_app_id
  github_app_installation_id = var.flux_github_app_installation_id
  github_app_pem             = var.flux_github_app_pem 

  git_url  = "https://github.com/black-quartz/flux-fleet-management.git"
  git_ref  = "refs/heads/main"
  git_path = "kubernetes/production"
}
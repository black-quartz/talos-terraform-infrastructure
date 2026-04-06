###############################
##### Talos Cluster Nodes ##### 
###############################
locals {
  cluster_endpoint_uri = "https://${var.cluster_endpoint}:6443"

  patch_files = fileset(path.module, "files/*.{yml,yaml}")

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

  config_patches = concat(
    [ file("${path.module}/nodes/controlplane/${each.key}.yml") ],
    [ for f in local.patch_files : file(f) ],
    [
      templatefile("${path.module}/templates/hostname-config.yml.tftpl", {
        hostname = each.value.hostname
      }),

      templatefile("${path.module}/templates/install-image.yml.tftpl", {
        install_image = data.talos_image_factory_urls.base.urls.installer
      })
    ]
  )
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
  create_duration = "60s"

  depends_on = [talos_machine_bootstrap.this]
}

### Cilium ###
module "cilium" {
  source = "./modules/cilium"

  cilium_version = "1.19.1"

  depends_on = [talos_machine_configuration_apply.controlplane]
}

module "coredns" {
  source = "./modules/coredns"

  coredns_version = "1.45.2"

  depends_on = [module.cilium]
}

### Longhorn ###
module "longhorn" {
  source = "./modules/longhorn"

  longhorn_default_data_path = "/var/lib/longhorn/data-1"

  depends_on = [module.cilium]
}

### Flux Operator ###
module "flux" {
  source = "./modules/flux"

  github_app_id              = var.flux_github_app_id
  github_app_installation_id = var.flux_github_app_installation_id
  github_app_pem             = var.flux_github_app_pem 

  git_url  = "https://github.com/black-quartz/flux-fleet-management.git"
  git_ref  = "refs/heads/main"
  git_path = "kubernetes/clusters/production"

  depends_on = [module.cilium]
}
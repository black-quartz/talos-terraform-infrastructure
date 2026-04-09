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
    [ for f in local.patch_files : file(f) ],
    [
      file("nodes/controlplane/${each.key}.yml"),

      templatefile("templates/cluster-network.yml.tftpl", {
        cluster_domain = var.cluster_domain
      }),

      templatefile("templates/hostname-config.yml.tftpl", {
        hostname = each.value.hostname
      }),

      templatefile("templates/install-image.yml.tftpl", {
        install_image = data.talos_image_factory_urls.base.urls.installer
      })
    ]
  )
}

resource "time_sleep" "before_bootstrap" {
  create_duration = "60s"

  depends_on = [talos_machine_bootstrap.this]
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

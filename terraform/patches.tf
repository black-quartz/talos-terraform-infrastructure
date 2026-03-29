
############################
#### Talos Node Patches ####
############################

locals {
    control_plane_files = fileset("${path.module}", "talos/nodes/controlplane/*.{yml,yaml}")

    control_plane_decoded = [
      for f in local.control_plane_files :
      yamldecode(file("${path.module}/${f}"))
    ]

    control_plane_nodes = {
      for config in local.control_plane_decoded :
      config.metadata.hostname => config
    }

    control_plane_node_patches = {
      for config in local.control_plane_decoded :
      config.metadata.hostname => yamlencode({
        machine = config.machine
    })
  }
}

############################
### Talos Config Patches ###
############################

locals {
    patches_directory = "${path.module}/talos/patches"

    control_plane_patch_file = "${local.patches_directory}/controlplane.yml"
    control_plane_patch      = file(local.control_plane_patch_file)

    cluster_patch_file = "${local.patches_directory}/cluster.yml"
    cluster_patch      = file(local.cluster_patch_file)

    cluster_identity_patch = yamlencode({
        cluster = {
            clusterName  = var.cluster_name
            controlPlane = {
                endpoint = "https://${var.cluster_endpoint}:6443"
            } 
        }
    })

    talos_image_patch = yamlencode({
      machine = {
        install = {
          image = data.talos_image_factory_urls.base.urls.installer
        }
      }
    })
}

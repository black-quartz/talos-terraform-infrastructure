###########################
### Talos Image Factory ###
###########################

locals {
    image_platform     = "metal"
    image_architecture = "amd64"
    image_extensions = [ # Must match the exact name of the extension on https://https://factory.talos.dev/
        "siderolabs/iscsi-tools",
        "siderolabs/util-linux-tools"
    ]
}

# Data object to retrieve names of image factory extensions
# available for the specified Talos Linux version
data "talos_image_factory_extensions_versions" "base" {
    talos_version = var.talos_version
    exact_filters = {
        names = local.image_extensions
    }
}

# Generates an image schematic from the desired extensions
resource "talos_image_factory_schematic" "base" {
    schematic = yamlencode({
        customization = {
            systemExtensions = {
                officialExtensions = data.talos_image_factory_extensions_versions.base.extensions_info.*.name
            }
        }
    })
}

# Generates the installer image for use in the machine config
# data.talos_image_factory_urls.base.installer
data "talos_image_factory_urls" "base" {
    schematic_id  = talos_image_factory_schematic.base.id
    talos_version = var.talos_version
    platform      = local.image_platform
    architecture  = local.image_architecture
}

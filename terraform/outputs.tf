output "machine_config" {
    value     = talos_machine_configuration_apply.controlplane["talos-01"].machine_configuration
    sensitive = true
}

output "talosconfig" {
    value     = data.talos_client_configuration.this.talos_config
    sensitive = true
}

output "kubeconfig" {
    value     = talos_cluster_kubeconfig.this.kubeconfig_raw
    sensitive = true
}

output "install_image" {
    value = data.talos_image_factory_urls.base.urls.installer
}
variable "talos_version" {
    type        = string
    description = "Talos version to use for the cluster."
    default     = "1.12.4"
}

variable "cluster_name" {
    type        = string
    description = "Name of the Talos Kubernetec cluster."
    default     = "talos-eastus0"
}

variable "cluster_endpoint" {
    type        = string
    description = "Address of the Talos API server."
    default     = "talos.labrynth.cloud"
}

variable "flux_github_app_id" {
    description = "GitHub App ID for Flux."
    type        = string
    nullable    = false
}

variable "flux_github_app_installation_id" {
    description = "GitHub App Installation ID for Flux."
    type        = string
    nullable    = false
}

variable "flux_github_app_pem" {
    description = "GitHub App Private Key for Flux."
    type        = string
    nullable    = false
}
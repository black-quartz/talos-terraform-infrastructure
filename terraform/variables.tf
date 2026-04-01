variable "talos_version" {
    type        = string
    description = "Talos version to use for the cluster."
    default     = "1.12.5"
}

variable "kubernetes_version" {
    type    = string
    default = "1.35.2"
}

variable "node_data" {
    type        = map(any)
    description = "Data about the nodes in the cluster."
    default     = {
        controlplanes = {
            talos-01 = {
                hostname = "talos-01"
                address  = "talos-01.blackquartz.internal"
            }
        }
    }
}
variable "cluster_name" {
    type        = string
    description = "Name of the Talos Kubernetes cluster."
    default     = "black-quartz-platform"
}

variable "cluster_endpoint" {
    type        = string
    description = "Address of the Talos API server."
    default     = "platform.blackquartz.io"
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
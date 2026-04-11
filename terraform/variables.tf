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
    type = object({
        controlplanes = optional(map(object({
            hostname = string
            address  = string
        })), {})
        workers = optional(map(object({
            hostname = string
            address  = string
        })), {})
    })
    description = "Data about the nodes in the cluster."
    
    default     = {
        controlplanes = {
            talos-01 = {
                hostname = "talos-01"
                address  = "talos-01.blackquartz.internal"
            }
        }
        workers = {}
    }
}
variable "cluster_name" {
    type        = string
    description = "Name of the Talos Kubernetes cluster."
    default     = "black-quartz-prod-us-1"
}

variable "cluster_endpoint" {
    type        = string
    description = "Address of the Talos API server."
    default     = "platform.blackquartz.io"
}

variable "cluster_domain" {
    type        = string
    description = "Internal domain used by the Kubernetes cluster."
    default     = "prod-us-1.blackquartz.io"
}

variable "cilium_loadbalancer_resources_enabled" {
    type        = bool
    description = "Whether to enable Cilium Load Balancer resources."
    default     = true
}
variable "kubernetes_host" {
    description = "The hostname (in the form of URI) of the Kubernetes API."
    type        = string
    nullable    = false
}

variable "cluster_ca_certificate" {
    description = "PEM-encoded root certificates bundle for TLS authentication."
    type        = string
    nullable    = false
}

variable "client_certificate" {
    description = "PEM-encoded client certificate for TLS authentication."
    type        = string
    nullable    = false
}

variable "client_key" {
    description = "PEM-encoded client certificate key for TLS authentication."
    type        = string
    nullable    = false
}

variable "cilium_version" {
    type = string
}

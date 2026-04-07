variable "cilium_version" {
    description = "Cilium helm chart version to deploy."
    type        = string
    nullable    = false
}

variable "load_balancer_ip_pool_cidrs" {
    description = "List of Cilium Load Balancer IP Pool CIDRs."
    type = list(object({
        cidr  = string
        start = string
        stop  = string
    }))
    default = []
}

variable "l2_announcement_interfaces" {
    description = "List of interfaces to use for L2 Load Balancer IP announcements."
    type        = list(string)
    default     = []
}
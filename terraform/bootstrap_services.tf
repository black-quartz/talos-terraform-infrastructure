##################################
### Cluster Bootstrap Services ###
##################################

resource "time_sleep" "after_bootstrap" {
  create_duration = "60s"

  depends_on = [talos_machine_bootstrap.this]
}

resource "helm_release" "cilium" {
  name       = "cilium"
  namespace  = "kube-system"
  repository = "oci://quay.io/cilium/charts" 
  chart      = "cilium"
  wait       = true
  
  values = [file("values/cilium.yml")]

  set = [
    {
        name  = "hubble.peerService.clusterDomain"
        value = var.cluster_domain
    },
  ]

  depends_on = [time_sleep.after_bootstrap]
}

resource "kubernetes_manifest" "lb_ip_pool" {
  count = var.cilium_loadbalancer_resources_enabled ? 1 : 0
  manifest = {
    apiVersion = "cilium.io/v2alpha1"
    kind       = "CiliumLoadBalancerIPPool"
    metadata = {
      name = "external-lb-pool"
    }
    spec = {
      blocks = [
        {
          cidr  = "10.20.80.0/24"
          start = "10.20.80.10"
          stop  = "10.20.80.254"
        }
      ]
    }
  }
}

resource "kubernetes_manifest" "l2_announcement_policy" {
  count = var.cilium_loadbalancer_resources_enabled ? 1 : 0
  manifest = {
    apiVersion = "cilium.io/v2alpha1"
    kind       = "CiliumL2AnnouncementPolicy"
    metadata = {
      name = "external-lb-policy"
    }
    spec = {
      externalIPs     = false
      loadBalancerIPs = true
      interfaces      = ["bond1"]
    }
  }
}

resource "helm_release" "coredns" {
  name       = "coredns"
  namespace  = "kube-system"
  repository = "https://coredns.github.io/helm" 
  chart      = "coredns"
  wait       = true
  
  values = [
    templatefile("values/coredns.yml.tftpl", {
        cluster_domain = var.cluster_domain
    })
]

  depends_on = [time_sleep.after_bootstrap]
}

resource "kubernetes_namespace_v1" "longhorn" {
    metadata {
      name   = "longhorn-system"
      labels = {
        "pod-security.kubernetes.io/enforce" = "privileged" # Required for Longhorn
      }
    }

    lifecycle {
      ignore_changes = [metadata]
    }

    depends_on = [helm_release.cilium]
}

resource "helm_release" "longhorn" {
  name       = "longhorn"
  namespace  = "longhorn-system"
  repository = "https://charts.longhorn.io"
  chart      = "longhorn"
  wait       = true
  
  values = [file("values/longhorn.yml")]

  set = [
    {
        name = "defaultSettings.defaultDataPath"
        value = "/var/lib/longhorn/data-1"
    }
  ]

  depends_on = [kubernetes_namespace_v1.longhorn]
}
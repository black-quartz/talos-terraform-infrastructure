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
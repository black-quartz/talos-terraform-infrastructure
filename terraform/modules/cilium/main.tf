resource "helm_release" "this" {
  name       = "cilium"
  namespace  = "kube-system"
  repository = "oci://quay.io/cilium/charts" 
  chart      = "cilium"
  version    = var.cilium_version
  wait       = true
  
  values = [file("${path.module}/values/base.yml")]
}

resource "kubernetes_manifest" "lb_ip_pool" {
  manifest = yamldecode(
    templatefile("${path.module}/templates/loadbalancer-ip-pool.yml.tftpl", {
      lb_ip_pool_cidrs = var.load_balancer_ip_pool_cidrs
    })
  )
}

resource "kubernetes_manifest" "l2_announcement_policy" {
  manifest = yamldecode(
    templatefile("${path.module}/templates/l2-announcement-policy.yml.tftpl", {
      l2_announcement_interfaces = var.l2_announcement_interfaces
    })
  )
}
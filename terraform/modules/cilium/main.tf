resource "helm_release" "this" {
  name       = "cilium"
  namespace  = "kube-system"
  repository = "oci://quay.io/cilium/charts" 
  chart      = "cilium"
  version    = var.cilium_version
  wait       = true
  
  values = [file("${path.module}/helm/values.yml")]
}
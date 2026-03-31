resource "helm_release" "this" {
  name      = var.release_name
  namespace = "kube-system"

  repository = "oci://quay.io/cilium/charts" 
  chart      = "cilium"
  version    = var.cilium_version

  values = [file("${path.module}/values.yml")]

  wait    = true
  timeout = 300 # 5m
}
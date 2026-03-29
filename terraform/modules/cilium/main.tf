resource "kubernetes_namespace" "this" {
    metadata {
        name = var.namespace
    }
}

resource "helm_release" "this" {
  name      = var.release_name
  namespace = var.namespace

  repository = "oci://quay.io/cilium/charts/" 
  chart      = "cilium"
  version    = var.cilium_version

  values = [file("${path.module}/values.yml")]

  wait = true
}
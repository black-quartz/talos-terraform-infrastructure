resource "kubernetes_namespace_v1" "this" {
    metadata {
      name = "longhorn-system"
    }
}

resource "helm_release" "this" {
  name      = var.release_name
  namespace = "longhorn-system"

  repository = "https://charts.longhorn.io"
  chart      = "longhorn"
  version    = var.longhorn_version

  values = [file("${path.module}/values.yml")]

  wait    = true
  timeout = 300 # 5m
}
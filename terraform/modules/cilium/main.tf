resource "kubernetes_namespace" "this" {
    metadata {
        name = var.namespace
    }
}

resource "helm_release" "this" {
  name      = var.release_name
  namespace = var.namespace

  repository = var.chart_repository
  chart      = var.chart_name
  version    = var.chart_version

  values = var.chart_values

  wait = true
}
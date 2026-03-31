resource "kubernetes_namespace_v1" "this" {
    metadata {
      name = "longhorn-system"
    }

    lifecycle {
      ignore_changes = [ metadata ]
    }
}

resource "helm_release" "this" {
  name       = "longhorn"
  namespace  = "longhorn-system"
  repository = "https://charts.longhorn.io"
  chart      = "longhorn"
  version    = var.longhorn_version
  wait       = true
  
  values = [
    yamlencode({
      defaultSettings = {
        defaultDataPath       = var.longhorn_default_data_path
        defaultReplicateCount = 1
        defaultDataLocaility  = "best-effort"
      }
      persistence = {
        defaultClass             = true
        defaultClassReplicaCount = 1
        defaultFsType            = "ext4"
      }
      service = {
        ui = {
          type = "ClusterIP"
        }
      }
      longhornUI = {
        log = {
          format = "json"
        }
      }
      longhornManager = {
        log = {
          format = "json"
        }
      }
      longhornDriver = {
        log = {
          format = "json"
        }
      }
    })
  ]

  depends_on = [ kubernetes_namespace_v1.this ]
}
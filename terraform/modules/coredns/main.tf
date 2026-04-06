resource "helm_release" "this" {
  name       = "coredns"
  namespace  = "kube-system"
  repository = "https://coredns.github.io/helm" 
  chart      = "coredns"
  version    = var.coredns_version
  wait       = true
  
  values = [
    yamlencode({
        podLabels = {
            "blackquartz.io/app" = "coredns"
            "blackquartz.io/env" = "core"
        }
        service = {
            name      = "kube-dns"
            clusterIP = "10.96.0.10"
        }
        extraConfig = {
            import = {
                parameters = "/opt/coredns/*.conf"
            }
        }
    })
  ]
}
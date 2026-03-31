# Create the flux-system namespace
resource "kubernetes_namespace_v1" "this" {
    metadata {
      name = "flux-system"
    }

    lifecycle {
        ignore_changes = [ metadata ]
    }
}

# Create a Kubernetes secret with the GitHub App credentials
resource "kubernetes_secret_v1" "this" {
    metadata {
      name      = "flux-system"
      namespace = "flux-system"
    }

    data = {
        githubAppID             = var.github_app_id
        githubAppInstallationID = var.github_app_installation_id
        githubAppPrivateKey     = var.github_app_pem
    }

    type = "Opaque"
}

# Install the Flux Operator
resource "helm_release" "flux_operator" {
  name       = "flux-operator"
  namespace  = "flux-system"
  repository = "oci://ghcr.io/controlplaneio-fluxcd/charts"
  chart      = "flux-operator"
  wait       = true

  depends_on = [ kubernetes_namespace_v1.this ]
}

# Deploy the Flux Instance
resource "helm_release" "flux_instance" {
    name       = "flux"
    namespace  = "flux-system"
    repository = "oci://ghcr.io/controlplaneio-fluxcd/charts"
    chart      = "flux-instance"
    wait       = true

    values = [
        yamlencode({
            instance = {
                distribution = {
                    version = var.flux_version
                }
                components = [
                    "source-controller",
                    "kustomize-controller",
                    "helm-controller",
                    "notification-controller",
                    "image-reflector-controller",
                    "image-automation-controller"
                ]
                cluster = {
                    type          = var.cluster_type
                    size          = var.cluster_size
                    networkPolicy = false
                    multitenant   = true
                }
                sync = {
                    kind       = "GitRepository"
                    provider   = "github"
                    pullSecret = "flux-system"
                    url        = var.git_url
                    ref        = var.git_ref
                    path       = var.git_path
                }
            }
        })
    ]

    depends_on = [
        kubernetes_namespace_v1.this,
        kubernetes_secret_v1.this,
        helm_release.flux_operator
    ]
}

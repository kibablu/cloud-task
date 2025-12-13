
# --- ArgoCD Helm Release ---
resource "helm_release" "argocd" {
  # Tell this resource to use the aliased providers configured in provider.tf
  provider = helm.chris_gke

  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  version          = "5.51.2"
  create_namespace = true

  # Configure values for the ArgoCD chart to use LoadBalancer
  values = [
    yamlencode({
      server = {
        service = {
          type = "LoadBalancer"
        }
      }
    })
  ]

  depends_on = [google_container_cluster.chris_gke_cluster]
}


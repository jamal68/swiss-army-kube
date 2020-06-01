data "helm_repository" "argo" {
  name = "argo"
  url  = "https://argoproj.github.io/argo-helm"
}

# Create namespace argo-cd
resource "kubernetes_namespace" "argo-cd" {
  depends_on = [
    var.module_depends_on
  ]
  metadata {
    name = "argo-cd"
  }
}

resource "helm_release" "argo-cd" {
  depends_on = [
    var.module_depends_on
  ]

  name          = "argo-cd"
  repository    = data.helm_repository.argo.metadata[0].name
  chart         = "argo-cd"
  namespace     = "argo-cd"
  recreate_pods = true

  set {
    name  = "server.ingress.enabled"
    value = true
  }

  dynamic "set" {
    for_each = var.domains
    content {
      name  = "server.ingress.hosts[${set.key}]"
      value = "argo-cd.${set.value}"
    }
  }

  dynamic "set" {
    for_each = var.domains
    content {
      name  = "server.ingress.tls[${set.key}].secretName"
      value = "argo-cd-${set.value}-tls"
    }
  }

  dynamic "set" {
    for_each = var.domains
    content {
      name  = "server.ingress.tls[${set.key}].hosts[0]"
      value = "argo-cd.${set.value}"
    }
  }

  set {
    name  = "server.config.url"
    value = "https://argo-cd.${var.domains[0]}"
  }

  values = [
    file("${path.module}/values.yml")
  ]
}

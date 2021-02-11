resource "helm_release" "kasten" {
  name       = "k10"
  repository = "https://charts.kasten.io"
  chart      = "k10"
  namespace  = "kasten-io"

  timeout    = 600
  depends_on = [module.kubernetes]

  set {
    name  = "secrets.azureTenantId"
    value = var.kasten_tenantid
  }

  set {
    name  = "secrets.azureClientId"
    value = var.kasten_clientid
  }

  set {
    name  = "secrets.azureClientSecret"
    value = var.kasten_clientsecret
  }
}

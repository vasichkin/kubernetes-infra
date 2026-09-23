resource "helm_release" "kube_prometheus_stack" {
  name       = "kube-prometheus-stack"
  namespace  = var.monitor_namespace
  version    = var.chart_version
  repository = "https://prometheus-community.github.io/helm-charts/"
  chart      = "kube-prometheus-stack"

  values = [
    templatefile("${path.module}/values.yaml.tftpl", {
      domain                     = var.domain
      grafana_anonymous_enabled  = var.grafana_anonymous_enabled
      prometheus_retention       = var.prometheus_retention
      prometheus_scrape_interval = var.prometheus_scrape_interval
    })
  ]
}

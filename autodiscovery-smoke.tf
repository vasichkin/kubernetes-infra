resource "kubernetes_deployment_v1" "autodiscovery_smoke" {
  count = var.verify_autodiscovery_smoke_test ? 1 : 0

  metadata {
    name      = "prometheus-autodiscovery-smoke"
    namespace = var.monitor_namespace
    labels = {
      app = "prometheus-autodiscovery-smoke"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "prometheus-autodiscovery-smoke"
      }
    }

    template {
      metadata {
        labels = {
          app = "prometheus-autodiscovery-smoke"
        }
        annotations = {
          "prometheus.io/scrape" = "true"
          "prometheus.io/port"   = "9100"
          "prometheus.io/path"   = "/metrics"
        }
      }

      spec {
        container {
          name  = "metrics"
          image = "prom/node-exporter:v1.8.2"

          port {
            container_port = 9100
            name           = "metrics"
          }

          args = [
            "--web.listen-address=:9100",
            "--collector.disable-defaults",
            "--collector.textfile",
          ]
        }
      }
    }
  }

  depends_on = [module.kube_prometheus_stack]
}

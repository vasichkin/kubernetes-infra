resource "kubernetes_ingress_v1" "grafana" {
  depends_on = [
    module.ingress_nginx,
    module.kube_prometheus_stack,
  ]

  metadata {
    name      = "grafana"
    namespace = var.monitor_namespace
    annotations = {
      "nginx.ingress.kubernetes.io/use-regex"      = "true"
      "nginx.ingress.kubernetes.io/rewrite-target" = "/$2"
    }
  }

  spec {
    ingress_class_name = var.ingress_class_name

    rule {
      host = var.domain
      http {
        path {
          path      = "/grafana(/|$)(.*)"
          path_type = "ImplementationSpecific"
          backend {
            service {
              name = "kube-prometheus-stack-grafana"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}

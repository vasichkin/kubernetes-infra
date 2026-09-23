resource "kubernetes_namespace_v1" "ingress_nginx" {
  metadata {
    name = var.ingress_namespace
  }
}

resource "helm_release" "ingress_nginx" {
  name       = "ingress-nginx"
  namespace  = kubernetes_namespace_v1.ingress_nginx.metadata[0].name
  version    = var.nginx_version
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  values = [
    templatefile("${path.module}/values.yaml.tftpl", {
      ingress_class_name = var.ingress_class_name
      http_node_port     = var.http_node_port
    })
  ]
}

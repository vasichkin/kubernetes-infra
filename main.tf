resource "kubernetes_namespace_v1" "monitoring" {
  metadata {
    name = var.monitor_namespace
  }
}

module "aws_ebs_csi_driver" {
  source = "./modules/aws-ebs-csi-driver"

  aws_region    = var.aws_region
  aws_tags      = var.aws_tags
  chart_version = var.aws_ebs_csi_driver_version
}

module "ingress_nginx" {
  source = "./modules/ingress-nginx"

  nginx_version      = var.ingress_nginx_version
  ingress_namespace  = var.ingress_namespace
  ingress_class_name = var.ingress_class_name
  http_node_port     = var.ingress_http_node_port
}

module "kube_prometheus_stack" {
  source = "./modules/kube-prometheus-stack"

  monitor_namespace          = kubernetes_namespace_v1.monitoring.metadata[0].name
  chart_version              = var.kube_prometheus_stack_version
  domain                     = var.domain
  grafana_anonymous_enabled  = var.grafana_anonymous_enabled
  prometheus_retention       = var.prometheus_retention
  prometheus_scrape_interval = var.prometheus_scrape_interval

  depends_on = [kubernetes_namespace_v1.monitoring]
}

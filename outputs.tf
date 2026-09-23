output "grafana_url" {
  description = "Grafana URL via ingress subpath"
  value       = "http://${var.domain}/grafana/"
}

output "grafana_admin_secret" {
  description = "kubectl command to read Grafana admin password"
  value       = "kubectl --kubeconfig ${var.kubeconfig_path} get secret -n ${var.monitor_namespace} kube-prometheus-stack-grafana -o jsonpath='{.data.admin-password}' | base64 --decode"
}

output "prometheus_service" {
  description = "In-cluster Prometheus service DNS name"
  value       = "kube-prometheus-stack-prometheus.${var.monitor_namespace}.svc:9090"
}

output "storage_class_name" {
  value = kubernetes_storage_class_v1.default_gp3.metadata[0].name
}

output "ingress_class" {
  value = var.ingress_class_name
}

output "verify_autodiscovery" {
  description = "Run after apply to validate Prometheus target discovery"
  value       = "KUBECONFIG=${var.kubeconfig_path} MONITOR_NAMESPACE=${var.monitor_namespace} EXPECT_SMOKE=${var.verify_autodiscovery_smoke_test} ./scripts/verify-prometheus-autodiscovery.sh"
}

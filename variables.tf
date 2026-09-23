variable "kubeconfig_path" {
  type        = string
  description = "Path to kubeconfig for the target cluster"
  default     = "kubeconfigs/config"
}

variable "aws_region" {
  type        = string
  description = "AWS region for EBS CSI controller"
}

variable "aws_tags" {
  type        = map(string)
  description = "Tags applied to dynamically provisioned EBS volumes"
}

variable "domain" {
  type        = string
  description = "Host for ingress (Grafana served under /grafana on this domain)"
}

variable "monitor_namespace" {
  type        = string
  description = "Namespace for kube-prometheus-stack"
  default     = "monitoring"
}

variable "ingress_namespace" {
  type        = string
  description = "Namespace for ingress-nginx"
  default     = "ingress-nginx"
}

variable "ingress_class_name" {
  type        = string
  description = "IngressClass name used by ingress-nginx and Grafana Ingress"
  default     = "nginx"
}

variable "ingress_http_node_port" {
  type        = number
  description = "Fixed NodePort for ingress-nginx controller HTTP; must match the ALB target group port for /grafana* in kubernetes-terraform-ansible's alb_path_routes"
  default     = 30300
}

variable "ingress_nginx_version" {
  type        = string
  description = "ingress-nginx Helm chart version"
  default     = "4.12.2"
}

variable "aws_ebs_csi_driver_version" {
  type        = string
  description = "aws-ebs-csi-driver Helm chart version"
  default     = "2.63.1"
}

variable "kube_prometheus_stack_version" {
  type        = string
  description = "kube-prometheus-stack Helm chart version"
  default     = "72.6.2"
}

variable "verify_autodiscovery_smoke_test" {
  type        = bool
  description = "Deploy a pod with prometheus.io scrape annotations to validate annotation-based autodiscovery"
  default     = true
}

variable "grafana_anonymous_enabled" {
  type        = bool
  description = "Enable Grafana anonymous admin access (demo-friendly; disable in production)"
  default     = true
}

variable "prometheus_retention" {
  type        = string
  description = "Prometheus TSDB retention (prometheusSpec.retention)"
  default     = "10d"
}

variable "prometheus_scrape_interval" {
  type        = string
  description = "Default scrape interval for Prometheus"
  default     = "30s"
}

variable "storage_class_name" {
  type        = string
  description = "Name of the default gp3 StorageClass"
  default     = "gp3-default"
}

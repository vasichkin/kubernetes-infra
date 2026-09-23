variable "monitor_namespace" {
  type = string
}

variable "chart_version" {
  type = string
}

variable "domain" {
  type = string
}

variable "grafana_anonymous_enabled" {
  type = bool
}

variable "prometheus_retention" {
  type = string
}

variable "prometheus_scrape_interval" {
  type = string
}

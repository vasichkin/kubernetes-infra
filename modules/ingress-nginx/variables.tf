variable "ingress_namespace" {
  type    = string
  default = "ingress-nginx"
}

variable "nginx_version" {
  type = string
}

variable "ingress_class_name" {
  type = string
}

variable "http_node_port" {
  type        = number
  description = "Fixed NodePort for controller HTTP; must match the ALB target group port in kubernetes-terraform-ansible's alb_path_routes"
}

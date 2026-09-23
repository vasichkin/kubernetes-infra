terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 3.2"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.2"
    }
  }

  # bucket/region are supplied at `tofu init` time via -backend-config
  # (see backend.hcl.example) since backend blocks cannot read variables or tfvars.
  backend "s3" {
    key = "terraform/kubernetes-infra-state"
  }
}

provider "kubernetes" {
  config_path = var.kubeconfig_path
}

provider "helm" {
  kubernetes = {
    config_path = var.kubeconfig_path
  }
}

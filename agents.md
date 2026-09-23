# Agent rules (Kubernetes platform / OpenTofu)

Conventions from this project. Apply the same patterns on similar **default cluster infra** repos unless the user overrides them.

## Scope and layering

- **Platform layer** (this kind of repo): cluster add-ons shared by all apps — ingress, storage CSI, default `StorageClass`, monitoring. No application workloads (WordPress, etc.) here.
- **App layer** (separate repo): namespaces, deployments, app ingress, app PVCs. Depends on platform already installed; do not duplicate ingress/CSI/monitoring in app repos.
- Prefer **AWS-oriented** defaults when the reference stack is EKS-like (EBS CSI, gp3). Call out when something is cloud-specific and not portable to minikube/docker-desktop.

## Primary tools

1. **OpenTofu (`tofu`)** is the primary provisioner — not raw `kubectl apply` for installable components.
2. **Modules** for each logical component (`modules/<name>/`); root wires modules only — no hardcoded chart versions or environment values in root module blocks.
3. **Helm** via `helm_release` whenever an official/community chart exists (ingress-nginx, kube-prometheus-stack, aws-ebs-csi-driver, etc.).

## Configuration: single root tfvars file

- All tunables live in root **`terraform.tfvars`** (gitignored). Ship **`terraform.tfvars.example`** with placeholders only.
- OpenTofu **auto-loads** `terraform.tfvars`; do not rely on a custom filename like `variables.tfvars` without `-var-file`.
- **Backend** bucket/region stay in **`backend.hcl`** (gitignored) + `backend.hcl.example`; they cannot come from tfvars (backend block limitation).
- **Kubeconfig** path is a variable (default `kubeconfigs/config`); kubeconfig dir is gitignored.

### What belongs in `terraform.tfvars`

Pass through from root to modules — do not hardcode in `main.tf` or static Helm values when the user might change them:

| Area | Examples |
|------|----------|
| Cloud | `aws_region`, `aws_tags` |
| Access | `kubeconfig_path`, `domain` |
| Namespaces | `monitor_namespace`, `ingress_namespace` |
| Ingress | `ingress_class_name`, `ingress_nginx_version` |
| Storage | `storage_class_name` |
| Helm chart versions | `aws_ebs_csi_driver_version`, `kube_prometheus_stack_version`, … |
| Monitoring tuning | `prometheus_retention`, `prometheus_scrape_interval`, `grafana_anonymous_enabled` |
| Verification | `verify_autodiscovery_smoke_test` |

Chart versions may have **defaults in `variables.tf`** matching the example file, but environment-specific values (domain, region, tags) stay required in tfvars with no fake defaults.

## Module and Helm conventions

- In modules, use **`templatefile("${path.module}/values.yaml.tftpl", { ... })`** or **`file("${path.module}/...")`** — never root-relative paths like `modules/foo/values.yaml` from inside a module.
- Declare **`hashicorp/kubernetes`** and **`hashicorp/helm`** in `required_providers` (both used).
- Prefer **`kubernetes_*_v1`** resources over deprecated unpinned types when the provider warns.
- Pin **Helm chart `version`** from a variable passed from root (EBS CSI, ingress, prometheus stack, etc.).

## Monitoring (Prometheus + Grafana)

- Install **one** chart: **`kube-prometheus-stack`** (Prometheus + Grafana + alertmanager), not separate ad-hoc installs unless the user asks otherwise.
- Enable **broad autodiscovery** in chart values:
  - `prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues: false`
  - `prometheus.prometheusSpec.podMonitorSelectorNilUsesHelmValues: false`
  - **`additionalScrapeConfigs`** job for pod annotations: `prometheus.io/scrape`, `port`, `path` (annotation-based-scrape).
- **Grafana on ingress subpath** when `domain` is set: `serve_from_sub_path: true`, `root_url` with `/grafana/`, plus `kubernetes_ingress_v1` with regex rewrite compatible with ingress-nginx; **`ingress_class_name`** from tfvars must match ingress controller `ingressClassResource.name`.
- Document Grafana admin password via cluster Secret; avoid committing credentials.

## Verification

- Provide a **post-apply script** (e.g. `scripts/verify-prometheus-autodiscovery.sh`) that port-forwards Prometheus and checks `/api/v1/targets`:
  - Minimum count of **UP** core targets (kubelet, node-exporter, etc.).
  - When smoke test enabled: at least one **UP** target for **`annotation-based-scrape`**.
- Optional **smoke Deployment** gated by `verify_autodiscovery_smoke_test` with standard `prometheus.io/*` pod annotations.
- Ingress controller metrics: prefer **pod** scrape annotations (or ServiceMonitor), not service annotations alone, if using pod-based annotation SD.

## Repo hygiene

- **Gitignore**: `.terraform/`, `terraform.tfvars`, `backend.hcl`, `kubeconfigs/`, state files. Commit **`.terraform.lock.hcl`** and **`terraform.tfvars.example`**.
- **Makefile** (optional): `init`, `plan`, `apply`, `setup-tfvars`, `verify` — plain `tofu plan` without extra `-var-file` once `terraform.tfvars` exists.
- **README**: prerequisites, init with `-backend-config=backend.hcl`, plan/apply, Grafana/Prometheus access, verification steps, layout table.

## Execution and safety

- Run **`tofu plan`** before apply; confirm tfvars values appear in plan output for wired variables.
- Do not **`tofu apply`** to a live cluster without explicit user approval when policy requires it.
- When reusing patterns from a sibling repo (e.g. `wordpress-k8s-terraform`), **port and fix** (path.module, tfvars centralization, split platform vs app) — do not copy root-relative template paths or duplicate platform modules in app repos.

## When in doubt

- Ask whether scope is **monitoring-only** vs **full platform** (ingress + CSI + storage class + monitoring).
- Ask how **Grafana** should be exposed: ingress subpath vs NodePort vs port-forward only.
- Ask before applying to production or shared clusters; warn on double-install if an app repo still owns the same Helm releases.

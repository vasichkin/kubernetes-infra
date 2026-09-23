# Agent rules — `kubernetes-infra` (platform layer)

This repository **is** the Kubernetes **platform layer**. It installs shared cluster infrastructure that application repos must not duplicate.

## What this repo owns


| Component                           | Location                                     | Notes                                                   |
| ----------------------------------- | -------------------------------------------- | ------------------------------------------------------- |
| AWS EBS CSI driver                  | `modules/aws-ebs-csi-driver`                 | Helm in `kube-system`                                   |
| Default gp3 StorageClass            | `storage.tf`                                 | `ebs.csi.aws.com`, default class annotation             |
| ingress-nginx                       | `modules/ingress-nginx`                      | DaemonSet, NodePort, metrics for Prometheus             |
| Prometheus + Grafana + Alertmanager | `modules/kube-prometheus-stack`              | Single `kube-prometheus-stack` chart                    |
| Grafana ingress (`/grafana`)        | `ingress-grafana.tf`                         | Subpath on `var.domain`, class `var.ingress_class_name` |
| Autodiscovery smoke test            | `autodiscovery-smoke.tf`                     | Gated by `verify_autodiscovery_smoke_test`              |
| Post-apply checks                   | `scripts/verify-prometheus-autodiscovery.sh` | Targets API, annotation-based scrape                    |


**Not in scope here:** application namespaces, deployments, app PVCs, app Ingress rules (e.g. WordPress). Those belong in an **app layer** repo such as `wordpress-k8s-terraform`.

## Stack position

```text
kubernetes-terraform-ansible   →  cluster (VPC, nodes, kubeconfig)
kubernetes-infra (this repo)     →  platform (CSI, StorageClass, ingress, monitoring)
<app-repo>                     →  workloads only; assumes platform is already applied
```

- Cluster must exist before `tofu apply` here; kubeconfig at `kubeconfigs/config` (gitignored).
- If an app repo still installs ingress-CSI-monitoring, **remove that duplication** there after this layer is live — avoid double Helm releases.



## Tools and layout

1. **OpenTofu (**`tofu`**)** — primary; use **modules** under `modules/<name>/`, root only wires variables into modules.
2. **Helm** — `helm_release` for charts that exist (EBS CSI, ingress-nginx, kube-prometheus-stack).
3. Root files: `provider.tf`, `variables.tf`, `main.tf`, `storage.tf`, `ingress-grafana.tf`, `outputs.tf`.

Module rules:

- Values: `templatefile("${path.module}/values.yaml.tftpl", …)` or `file("${path.module}/…")` — no paths relative to repo root from inside a module.
- Providers: `hashicorp/kubernetes` and `hashicorp/helm` in `required_providers`.
- Prefer `kubernetes_*_v1` resources.
- Chart **versions** and environment knobs come from root variables — not hardcoded in `main.tf` module blocks.



## Configuration

- `terraform.tfvars` (gitignored): all tunables; OpenTofu auto-loads it — use plain `tofu plan` / `tofu apply`.
- `terraform.tfvars.example`: committed placeholders; `make setup-tfvars` copies if missing.
- `backend.hcl` (gitignored) + `backend.hcl.example`: S3 bucket/region at `tofu init -backend-config=backend.hcl` (cannot live in tfvars).

Required / typical tfvars (see example file): `aws_region`, `aws_tags`, `domain`, `kubeconfig_path`, `monitor_namespace`, `ingress_namespace`, `ingress_class_name`, `aws_ebs_csi_driver_version`, `ingress_nginx_version`, `kube_prometheus_stack_version`, monitoring and verification flags.

Defaults in `variables.tf` are only for chart versions and non-environment flags; **domain, region, and tags stay required in tfvars**.

## Monitoring behavior (fixed for this repo)

- **Autodiscovery:** `serviceMonitorSelectorNilUsesHelmValues: false`, `podMonitorSelectorNilUsesHelmValues: false`, plus `additionalScrapeConfigs` job `annotation-based-scrape` (`prometheus.io/scrape`, `port`, `path`).
- **Grafana:** served under `http://<domain>/grafana/` via ingress subpath (`serve_from_sub_path`, `root_url` in chart values); ingress class must match `ingress_class_name` in ingress-nginx values.
- **Credentials:** Grafana admin password in cluster Secret only; document retrieval in README, never commit.



## Verification

After apply: `make verify` or run `scripts/verify-prometheus-autodiscovery.sh` (see README). Expect core targets UP and, when smoke test is on, at least one UP `annotation-based-scrape` target.

## Hygiene and workflow

- Gitignore: `terraform.tfvars`, `backend.hcl`, `kubeconfigs/`, `.terraform/`, state. Commit `.terraform.lock.hcl` and `terraform.tfvars.example`.
- Makefile: `init`, `plan`, `apply`, `setup-tfvars`, `verify`.
- Run `tofu plan` before apply; plan output should reflect tfvars (domain, versions, namespaces, tags).
- Do `tofu apply` to a live cluster only with explicit user approval when policy requires it.



## AWS assumptions

EBS CSI and gp3 default StorageClass are **AWS-specific**. For local clusters (minikube, docker-desktop), call out incompatibility or alternate modules — do not silently apply this stack unchanged.

## When changing this repo

- New platform capability → new `modules/<name>/` + variables in `variables.tf` / example tfvars + README layout table.
- Do not add app workloads or app-specific Ingress paths except platform UIs (Grafana).
- Reference implementation patterns live in sibling `wordpress-k8s-terraform` **only to port fixes** (path.module, tfvars); platform code stays here.



## When in doubt

- Confirm the user wants a change to **platform** scope, not an app concern.
- Warn before apply on shared/production clusters or if app repos still own the same releases.
- For Grafana exposure changes (subpath vs NodePort vs port-forward only), confirm with the user — **default for this repo is ingress subpath on** `domain`**.**


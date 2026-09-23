# kubernetes-infra

Default Kubernetes platform layer: AWS EBS CSI, default `gp3` StorageClass, ingress-nginx, and monitoring (Prometheus + Grafana via [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)).

OpenTofu is the primary tool; Helm charts are used where available. Configuration lives in root **`terraform.tfvars`** (auto-loaded by `tofu plan` / `tofu apply`).

## Prerequisites

- Existing cluster (for example from [kubernetes-terraform-ansible](https://github.com/vasichkin/kubernetes-terraform-ansible))
- OpenTofu (`tofu`)
- `kubectl`, `jq`, `curl`
- AWS workers with IAM/instance profile for the EBS CSI driver
- Copy kubeconfig to `kubeconfigs/config`
- Copy `backend.hcl.example` → `backend.hcl` and set S3 bucket/region
- Copy `terraform.tfvars.example` → `terraform.tfvars` and fill values

## Quick start (after clone)

```bash
cp backend.hcl.example backend.hcl    # set S3 bucket/region
make setup-tfvars                       # creates terraform.tfvars from example if missing
# edit terraform.tfvars; place kubeconfig at kubeconfigs/config
make init
make plan
make apply
make verify   # after apply completes
```

## Grafana

- URL: `http://<domain>/grafana/` (ingress subpath; set `domain` in `terraform.tfvars`)
- Admin password:

```bash
kubectl --kubeconfig kubeconfigs/config get secret -n monitoring kube-prometheus-stack-grafana \
  -o jsonpath="{.data.admin-password}" | base64 --decode; echo
```

Port-forward alternative:

```bash
kubectl --kubeconfig kubeconfigs/config -n monitoring port-forward svc/kube-prometheus-stack-grafana 3000:80
```

## Prometheus

Port-forward:

```bash
kubectl --kubeconfig kubeconfigs/config -n monitoring port-forward svc/kube-prometheus-stack-prometheus 9090:9090
```

In-cluster: `kube-prometheus-stack-prometheus.monitoring.svc:9090`

## Autodiscovery verification

Prometheus is configured for:

- **ServiceMonitors / PodMonitors** cluster-wide (`serviceMonitorSelectorNilUsesHelmValues: false`, same for pod monitors)
- **Pod annotation scraping** via job `annotation-based-scrape` (`prometheus.io/scrape`, `port`, `path`)

When `verify_autodiscovery_smoke_test = true` in `terraform.tfvars`, a small Deployment with scrape annotations is created in the monitoring namespace.

After apply:

```bash
KUBECONFIG=kubeconfigs/config MONITOR_NAMESPACE=monitoring EXPECT_SMOKE=true \
  ./scripts/verify-prometheus-autodiscovery.sh
```

Or: `make verify`

The script checks:

- At least **5** targets in **UP** state (core cluster exporters / kube components)
- At least **1** **UP** target for job **`annotation-based-scrape`** when smoke test is enabled

Manual inspection: open Prometheus → Status → Targets and confirm jobs such as `kubelet`, `node-exporter`, and `annotation-based-scrape`.

## Layout

| Component | Module / file |
|-----------|----------------|
| EBS CSI | `modules/aws-ebs-csi-driver` |
| StorageClass | `storage.tf` |
| ingress-nginx | `modules/ingress-nginx` |
| Prometheus + Grafana | `modules/kube-prometheus-stack` |
| Grafana ingress | `ingress-grafana.tf` |
| Smoke test pod | `autodiscovery-smoke.tf` |

Application workloads (for example WordPress) belong in a separate repo; install this layer first to avoid duplicate ingress/CSI/monitoring.

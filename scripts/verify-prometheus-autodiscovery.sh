#!/usr/bin/env bash
set -euo pipefail

KUBECONFIG="${KUBECONFIG:-kubeconfigs/config}"
MONITOR_NAMESPACE="${MONITOR_NAMESPACE:-monitoring}"
EXPECT_SMOKE="${EXPECT_SMOKE:-true}"
MIN_CORE_TARGETS="${MIN_CORE_TARGETS:-5}"
PROMETHEUS_SVC="${PROMETHEUS_SVC:-kube-prometheus-stack-prometheus}"
PROMETHEUS_PORT="${PROMETHEUS_PORT:-9090}"
TIMEOUT_SEC="${TIMEOUT_SEC:-120}"

export KUBECONFIG

if ! command -v kubectl >/dev/null 2>&1; then
  echo "kubectl is required" >&2
  exit 1
fi
if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required" >&2
  exit 1
fi

kubectl get ns "${MONITOR_NAMESPACE}" >/dev/null

PF_PID=""
cleanup() {
  if [[ -n "${PF_PID}" ]] && kill -0 "${PF_PID}" 2>/dev/null; then
    kill "${PF_PID}" 2>/dev/null || true
    wait "${PF_PID}" 2>/dev/null || true
  fi
}
trap cleanup EXIT

kubectl port-forward -n "${MONITOR_NAMESPACE}" "svc/${PROMETHEUS_SVC}" "${PROMETHEUS_PORT}:${PROMETHEUS_PORT}" >/dev/null 2>&1 &
PF_PID=$!

deadline=$((SECONDS + TIMEOUT_SEC))
until curl -sf "http://127.0.0.1:${PROMETHEUS_PORT}/-/ready" >/dev/null 2>&1; do
  if (( SECONDS >= deadline )); then
    echo "Prometheus did not become ready within ${TIMEOUT_SEC}s" >&2
    exit 1
  fi
  sleep 2
done

TARGETS_JSON="$(curl -sf "http://127.0.0.1:${PROMETHEUS_PORT}/api/v1/targets")"
ACTIVE="$(echo "${TARGETS_JSON}" | jq '[.data.activeTargets[] | select(.health == "up")] | length')"
echo "Active UP targets: ${ACTIVE}"

if (( ACTIVE < MIN_CORE_TARGETS )); then
  echo "Expected at least ${MIN_CORE_TARGETS} UP targets; got ${ACTIVE}" >&2
  echo "${TARGETS_JSON}" | jq '[.data.activeTargets[] | {job: .labels.job, health: .health}]' >&2
  exit 1
fi

ANNOTATION_UP="$(echo "${TARGETS_JSON}" | jq '[.data.activeTargets[] | select(.labels.job == "annotation-based-scrape" and .health == "up")] | length')"
echo "annotation-based-scrape UP targets: ${ANNOTATION_UP}"

if [[ "${EXPECT_SMOKE}" == "true" ]]; then
  if (( ANNOTATION_UP < 1 )); then
    echo "Expected at least 1 UP target for job annotation-based-scrape (smoke test enabled)" >&2
    echo "${TARGETS_JSON}" | jq '[.data.activeTargets[] | select(.labels.job == "annotation-based-scrape") | {health, scrapeUrl}]' >&2
    exit 1
  fi
  echo "Autodiscovery smoke test: OK"
else
  echo "Smoke test skipped (EXPECT_SMOKE=${EXPECT_SMOKE})"
fi

echo "Prometheus autodiscovery verification passed."

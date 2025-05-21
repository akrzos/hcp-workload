#!/usr/bin/env bash
# Source kubeconfigs.sh first

if [ -z "$1" ]; then
  START_TIME=$(date -d "1 hour ago" +%s)
else
  START_TIME=$1
fi

if [ -z "$2" ]; then
  END_TIME=$(date +%s)
else
  END_TIME=$2
fi

STEP_SIZE="15s"

MC_PROM_TOKEN=$(oc --kubeconfig ${MC_KUBECONFIG} create token prometheus-k8s -n openshift-monitoring)
MC_PROM_URL="https://$(oc --kubeconfig ${MC_KUBECONFIG} get routes -n openshift-monitoring thanos-querier -o 'jsonpath={.spec.host}')"
PROM_TOKEN=${MC_PROM_TOKEN} envsubst < scripts/promtool.http.config.yml.tmpl > scripts/mc.promtool.http.config.yml

# HC_PROM_TOKEN=$(oc --kubeconfig ${HC_KUBECONFIG} create token prometheus-k8s -n openshift-monitoring)
# HC_PROM_URL="https://$(oc --kubeconfig ${HC_KUBECONFIG} get routes -n openshift-monitoring thanos-querier -o 'jsonpath={.spec.host}')"
# PROM_TOKEN=${HC_PROM_TOKEN} envsubst < promntool.http.config.yml.tmpl > hc.promtool.http.config.yml

kas_cpu="node_namespace_pod_container:container_cpu_usage_seconds_total:sum_irate{namespace=\"${HC_NS}\", pod=~\"kube-apiserver-.*\", container=\"kube-apiserver\"}"

echo "--- HC Single KAS Container Usage ---"
# echo "promtool query range $MC_PROM_URL --http.config.file=scripts/mc.promtool.http.config.yml --start=$START_TIME --end=$END_TIME --step=$STEP_SIZE \"$kas_cpu\" -o json | jq '[.[] | .values[] | .[1] | tonumber]'"
all_kas_container_cpu_usage=$(promtool query range $MC_PROM_URL --http.config.file=scripts/mc.promtool.http.config.yml --start=$START_TIME --end=$END_TIME --step=$STEP_SIZE "$kas_cpu" -o json | jq '[.[] | .values[] | .[1] | tonumber]')
echo "$all_kas_container_cpu_usage" | python scripts/stats.py | column -t

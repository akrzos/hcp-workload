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

# KAS Queries
kas_cpu="node_namespace_pod_container:container_cpu_usage_seconds_total:sum_irate{namespace=\"${HC_NS}\", pod=~\"kube-apiserver-.*\", container=\"kube-apiserver\"}"
kas_cpu_sum="sum(node_namespace_pod_container:container_cpu_usage_seconds_total:sum_irate{namespace=\"${HC_NS}\", pod=~\"kube-apiserver-.*\", container=\"kube-apiserver\"})"

kas_mem="container_memory_working_set_bytes{namespace=\"${HC_NS}\", pod=~\"kube-apiserver-.*\", container=\"kube-apiserver\"} / 1024 / 1024 / 1024"
kas_mem_sum="sum(container_memory_working_set_bytes{namespace=\"${HC_NS}\", pod=~\"kube-apiserver-.*\", container=\"kube-apiserver\"}) / 1024 / 1024 / 1024"

# Etcd Queries
etcd_cpu="node_namespace_pod_container:container_cpu_usage_seconds_total:sum_irate{namespace=\"${HC_NS}\", pod=~\"etcd-.*\", container=\"etcd\"}"
etcd_cpu_sum="sum(node_namespace_pod_container:container_cpu_usage_seconds_total:sum_irate{namespace=\"${HC_NS}\", pod=~\"etcd-.*\", container=\"etcd\"})"

etcd_mem="container_memory_working_set_bytes{namespace=\"${HC_NS}\", pod=~\"etcd-.*\", container=\"etcd\"} / 1024 / 1024 / 1024"
etcd_mem_sum="sum(container_memory_working_set_bytes{namespace=\"${HC_NS}\", pod=~\"etcd-.*\", container=\"etcd\"}) / 1024 / 1024 / 1024"

# "Single" Queries, containers list of samples are all analyzed to find stats across each container for a specific pod (Ex kube-apiserver-0 and kube-apiserver-1 all samples are "appended" and stats ran over)

echo "--- HC Single KAS Container CPU Usage (Cores) ---"
# echo "promtool query range $MC_PROM_URL --http.config.file=scripts/mc.promtool.http.config.yml --start=$START_TIME --end=$END_TIME --step=$STEP_SIZE \"$kas_cpu\" -o json | jq '[.[] | .values[] | .[1] | tonumber]'"
cpu_usage_json=$(promtool query range $MC_PROM_URL --http.config.file=scripts/mc.promtool.http.config.yml --start=$START_TIME --end=$END_TIME --step=$STEP_SIZE "$kas_cpu" -o json | jq '[.[] | .values[] | .[1] | tonumber]')
echo "$cpu_usage_json" | python scripts/stats.py | column -t

echo "--- HC Single KAS Container Memory Usage (GiB) ---"
# echo "promtool query range $MC_PROM_URL --http.config.file=scripts/mc.promtool.http.config.yml --start=$START_TIME --end=$END_TIME --step=$STEP_SIZE \"$kas_mem\" -o json | jq '[.[] | .values[] | .[1] | tonumber]'"
mem_usage_json=$(promtool query range $MC_PROM_URL --http.config.file=scripts/mc.promtool.http.config.yml --start=$START_TIME --end=$END_TIME --step=$STEP_SIZE "$kas_mem" -o json | jq '[.[] | .values[] | .[1] | tonumber]')
echo "$mem_usage_json" | python scripts/stats.py | column -t

echo "--- HC Single Etcd Container CPU Usage (Cores) ---"
# echo "promtool query range $MC_PROM_URL --http.config.file=scripts/mc.promtool.http.config.yml --start=$START_TIME --end=$END_TIME --step=$STEP_SIZE \"$etcd_cpu\" -o json | jq '[.[] | .values[] | .[1] | tonumber]'"
cpu_usage_json=$(promtool query range $MC_PROM_URL --http.config.file=scripts/mc.promtool.http.config.yml --start=$START_TIME --end=$END_TIME --step=$STEP_SIZE "$etcd_cpu" -o json | jq '[.[] | .values[] | .[1] | tonumber]')
echo "$cpu_usage_json" | python scripts/stats.py | column -t

echo "--- HC Single Etcd Container Memory Usage (GiB) ---"
# echo "promtool query range $MC_PROM_URL --http.config.file=scripts/mc.promtool.http.config.yml --start=$START_TIME --end=$END_TIME --step=$STEP_SIZE \"$etcd_mem\" -o json | jq '[.[] | .values[] | .[1] | tonumber]'"
mem_usage_json=$(promtool query range $MC_PROM_URL --http.config.file=scripts/mc.promtool.http.config.yml --start=$START_TIME --end=$END_TIME --step=$STEP_SIZE "$etcd_mem" -o json | jq '[.[] | .values[] | .[1] | tonumber]')
echo "$mem_usage_json" | python scripts/stats.py | column -t


# "Total" Queries, containers are summed together to find stats (Ex etcd-0, etcd-1, etcd-2 pods etcd container is summed per sample then stats over each sample)

echo "--- HC KAS Containers Total CPU Usage (Cores) ---"
# echo "promtool query range $MC_PROM_URL --http.config.file=scripts/mc.promtool.http.config.yml --start=$START_TIME --end=$END_TIME --step=$STEP_SIZE \"$kas_cpu_sum\" -o json | jq '[.[] | .values[] | .[1] | tonumber]'"
cpu_usage_sum_json=$(promtool query range $MC_PROM_URL --http.config.file=scripts/mc.promtool.http.config.yml --start=$START_TIME --end=$END_TIME --step=$STEP_SIZE "$kas_cpu_sum" -o json | jq '[.[] | .values[] | .[1] | tonumber]')
echo "$cpu_usage_sum_json" | python scripts/stats.py | column -t

echo "--- HC KAS Containers Total Memory Usage (GiB) ---"
# echo "promtool query range $MC_PROM_URL --http.config.file=scripts/mc.promtool.http.config.yml --start=$START_TIME --end=$END_TIME --step=$STEP_SIZE \"$kas_mem_sum\" -o json | jq '[.[] | .values[] | .[1] | tonumber]'"
mem_usage_sum_json=$(promtool query range $MC_PROM_URL --http.config.file=scripts/mc.promtool.http.config.yml --start=$START_TIME --end=$END_TIME --step=$STEP_SIZE "$kas_mem_sum" -o json | jq '[.[] | .values[] | .[1] | tonumber]')
echo "$mem_usage_sum_json" | python scripts/stats.py | column -t

echo "--- HC Etcd Containers Total CPU Usage (Cores) ---"
# echo "promtool query range $MC_PROM_URL --http.config.file=scripts/mc.promtool.http.config.yml --start=$START_TIME --end=$END_TIME --step=$STEP_SIZE \"$etcd_cpu_sum\" -o json | jq '[.[] | .values[] | .[1] | tonumber]'"
cpu_usage_sum_json=$(promtool query range $MC_PROM_URL --http.config.file=scripts/mc.promtool.http.config.yml --start=$START_TIME --end=$END_TIME --step=$STEP_SIZE "$etcd_cpu_sum" -o json | jq '[.[] | .values[] | .[1] | tonumber]')
echo "$cpu_usage_sum_json" | python scripts/stats.py | column -t

echo "--- HC Etcd Containers Total Memory Usage (GiB) ---"
# echo "promtool query range $MC_PROM_URL --http.config.file=scripts/mc.promtool.http.config.yml --start=$START_TIME --end=$END_TIME --step=$STEP_SIZE \"$etcd_mem_sum\" -o json | jq '[.[] | .values[] | .[1] | tonumber]'"
mem_usage_sum_json=$(promtool query range $MC_PROM_URL --http.config.file=scripts/mc.promtool.http.config.yml --start=$START_TIME --end=$END_TIME --step=$STEP_SIZE "$etcd_mem_sum" -o json | jq '[.[] | .values[] | .[1] | tonumber]')
echo "$mem_usage_sum_json" | python scripts/stats.py | column -t

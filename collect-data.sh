#!/usr/bin/env bash
# Collect diagnostic data off MC, HCP, and HC
# set -e
# set -o pipefail

data_dir=$1
if [[ -n "$2" ]]; then
  kb_start_time=$2
fi
if [[ -n "$3" ]]; then
  kb_end_time=$3
fi

echo "$(date -u +%Y%m%d-%H%M%S) :: Collecting MC Data"

oc --kubeconfig ${MC_KUBECONFIG} get clusterversion > ${data_dir}/mc.clusterversion
oc --kubeconfig ${MC_KUBECONFIG} get clusteroperators > ${data_dir}/mc.clusteroperators
oc --kubeconfig ${MC_KUBECONFIG} get no > ${data_dir}/mc.nodes

echo "$(date -u +%Y%m%d-%H%M%S) :: Collecting HCP Data"

oc --kubeconfig ${MC_KUBECONFIG} get po -n ${HC_NS} -o wide > ${data_dir}/hcp.pods

# Container restarts
oc --kubeconfig ${MC_KUBECONFIG} get po -n ${HC_NS} -o json | jq -r '.items[] | .metadata.name as $podname | .status.containerStatuses[] | [$podname, .restartCount, .name ] | @tsv' | column -t > ${data_dir}/hcp.containers.restarts

oc --kubeconfig ${MC_KUBECONFIG} get po -n ${HC_NS} -l app=kube-apiserver -o wide > ${data_dir}/hcp.pods.kas
oc --kubeconfig ${MC_KUBECONFIG} get po -n ${HC_NS} -l app=kube-apiserver -o yaml > ${data_dir}/hcp.pods.kas.yml
oc --kubeconfig ${MC_KUBECONFIG} get po -n ${HC_NS} -l app=etcd -o wide > ${data_dir}/hcp.pods.etcd
oc --kubeconfig ${MC_KUBECONFIG} get po -n ${HC_NS} -l app=etcd -o yaml > ${data_dir}/hcp.pods.etcd.yml

echo "$(date -u +%Y%m%d-%H%M%S) :: Collecting HC Data"

oc --kubeconfig ${HC_KUBECONFIG} get clusterversion > ${data_dir}/hc.clusterversion
oc --kubeconfig ${HC_KUBECONFIG} get clusteroperators > ${data_dir}/hc.clusteroperators
oc --kubeconfig ${HC_KUBECONFIG} get no -A > ${data_dir}/hc.nodes

oc --kubeconfig ${HC_KUBECONFIG} get ns > ${data_dir}/hc.namespaces
oc --kubeconfig ${HC_KUBECONFIG} get po -A -o wide > ${data_dir}/hc.pods

oc --kubeconfig ${HC_KUBECONFIG} get crds -A -o wide > ${data_dir}/hc.crds

echo "$(date -u +%Y%m%d-%H%M%S) :: Finished Data Collection"

# Things I want shown in run log
echo "$(date -u +%Y%m%d-%H%M%S) :: KAS and Etcd Restarts"
# oc --kubeconfig ${MC_KUBECONFIG} get po -n ${HC_NS} -l app=kube-apiserver -o json | jq -r '.items[] | .metadata.name as $podname | .status.containerStatuses[] | [$podname, .restartCount, .name ] | @tsv'
# oc --kubeconfig ${MC_KUBECONFIG} get po -n ${HC_NS} -l app=etcd -o json | jq -r '.items[] | .metadata.name as $podname | .status.containerStatuses[] | [$podname, .restartCount, .name ] | @tsv'
oc --kubeconfig ${MC_KUBECONFIG} get po -n ${HC_NS} -l app=kube-apiserver
oc --kubeconfig ${MC_KUBECONFIG} get po -n ${HC_NS} -l app=etcd --no-headers

# Collect Metrics
if [[ -n "$kb_start_time" ]]; then
  ./scripts/metrics.sh ${kb_start_time} ${kb_end_time}
fi

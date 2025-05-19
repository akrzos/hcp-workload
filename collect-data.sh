#!/usr/bin/env bash
# Collect diagnostic data off MC, HCP, and HC
# set -e
# set -o pipefail

data_dir=$1

echo "Data Dir: ${data_dir}"

echo "$(date -u +%Y%m%d-%H%M%S) :: Collecting MC Data"

oc --kubeconfig ${MC_KUBECONFIG} get clusterversion > ${data_dir}/mc.clusterversion
oc --kubeconfig ${MC_KUBECONFIG} get clusteroperators > ${data_dir}/mc.clusteroperators
oc --kubeconfig ${MC_KUBECONFIG} get no > ${data_dir}/mc.nodes

echo "$(date -u +%Y%m%d-%H%M%S) :: Collecting HCP Data"

oc --kubeconfig ${MC_KUBECONFIG} get po -n ${HC_NS} -o wide > ${data_dir}/hcp.pods

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

echo "$(date -u +%Y%m%d-%H%M%S) :: Finished Data Collection"

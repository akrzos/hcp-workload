#!/usr/bin/env bash
# Collect diagnostic data off MC, HCP, and HC after kube-burner cleaning run
# set -e
# set -o pipefail

data_dir=$1

echo "$(date -u +%Y%m%d-%H%M%S) :: Collecting Post Clean Diagnostic Data"

echo "$(date -u +%Y%m%d-%H%M%S) :: Collecting MC Data"

oc --kubeconfig ${MC_KUBECONFIG} get clusterversion > ${data_dir}/mc.clusterversion
oc --kubeconfig ${MC_KUBECONFIG} get clusteroperators > ${data_dir}/mc.clusteroperators
oc --kubeconfig ${MC_KUBECONFIG} get no > ${data_dir}/mc.nodes
oc --kubeconfig ${MC_KUBECONFIG} describe no > ${data_dir}/mc.nodes.describe

oc --kubeconfig ${MC_KUBECONFIG} get po -A -o wide > ${data_dir}/mc.pods

oc --kubeconfig ${MC_KUBECONFIG} get hcp -A > ${data_dir}/mc.hcp
oc --kubeconfig ${MC_KUBECONFIG} get hcp -A -o yaml > ${data_dir}/mc.hcp.yaml
oc --kubeconfig ${MC_KUBECONFIG} get hc -A > ${data_dir}/mc.hc
oc --kubeconfig ${MC_KUBECONFIG} get hc -A -o yaml > ${data_dir}/mc.hc.yaml
oc --kubeconfig ${MC_KUBECONFIG} get nodepool -A > ${data_dir}/mc.nodepool
oc --kubeconfig ${MC_KUBECONFIG} get nodepool -A -o yaml > ${data_dir}/mc.nodepool.yaml
oc --kubeconfig ${MC_KUBECONFIG} get vpa -A > ${data_dir}/mc.vpa
oc --kubeconfig ${MC_KUBECONFIG} get vpa -A -o yaml > ${data_dir}/mc.vpa.yaml

oc --kubeconfig ${MC_KUBECONFIG} get hc -A -o json | jq '.items[] | "\(.metadata.name) :: hosted-cluster-size :: \(.metadata.labels["hypershift.openshift.io/hosted-cluster-size"])"' > ${data_dir}/mc.hc.hosted-cluster-size
oc --kubeconfig ${MC_KUBECONFIG} get hc -A -o json | jq '.items[] | "\(.metadata.name) :: recommended-cluster-size :: \(.metadata.annotations["hypershift.openshift.io/recommended-cluster-size"])"' > ${data_dir}/mc.hc.recommended-cluster-size

oc --kubeconfig ${MC_KUBECONFIG} get no --no-headers -l hypershift.openshift.io/cluster=${HC_NS} > ${data_dir}/mc.hc.request-serving-nodes
oc --kubeconfig ${MC_KUBECONFIG} describe no --no-headers -l hypershift.openshift.io/cluster=${HC_NS} > ${data_dir}/mc.hc.request-serving-nodes.describe
oc --kubeconfig ${MC_KUBECONFIG} get no --no-headers -l hypershift.openshift.io/cluster=${HC_NS} -o yaml > ${data_dir}/mc.hc.request-serving-nodes.yml

echo "$(date -u +%Y%m%d-%H%M%S) :: Collecting HCP Data"

oc --kubeconfig ${MC_KUBECONFIG} get po -n ${HC_NS} -o wide > ${data_dir}/hcp.pods

# Container restarts
oc --kubeconfig ${MC_KUBECONFIG} get po -n ${HC_NS} -o json | jq -r '.items[] | .metadata.name as $podname | .status.containerStatuses[] | [$podname, .restartCount, .name ] | @tsv' | column -t > ${data_dir}/hcp.containers.restarts

oc --kubeconfig ${MC_KUBECONFIG} get po -n ${HC_NS} -l app=kube-apiserver -o wide > ${data_dir}/hcp.pods.kas
oc --kubeconfig ${MC_KUBECONFIG} describe po -n ${HC_NS} -l app=kube-apiserver > ${data_dir}/hcp.pods.kas.describe
oc --kubeconfig ${MC_KUBECONFIG} get po -n ${HC_NS} -l app=kube-apiserver -o yaml > ${data_dir}/hcp.pods.kas.yml
oc --kubeconfig ${MC_KUBECONFIG} get po -n ${HC_NS} -l app=etcd -o wide > ${data_dir}/hcp.pods.etcd
oc --kubeconfig ${MC_KUBECONFIG} describe po -n ${HC_NS} -l app=etcd > ${data_dir}/hcp.pods.etcd.describe
oc --kubeconfig ${MC_KUBECONFIG} get po -n ${HC_NS} -l app=etcd -o yaml > ${data_dir}/hcp.pods.etcd.yml

echo "$(date -u +%Y%m%d-%H%M%S) :: Collecting HC Data"

oc --kubeconfig ${HC_KUBECONFIG} get clusterversion > ${data_dir}/hc.clusterversion 2>&1
oc --kubeconfig ${HC_KUBECONFIG} get clusteroperators > ${data_dir}/hc.clusteroperators 2>&1
oc --kubeconfig ${HC_KUBECONFIG} get no > ${data_dir}/hc.nodes 2>&1
oc --kubeconfig ${HC_KUBECONFIG} describe no > ${data_dir}/hc.nodes.describe 2>&1

oc --kubeconfig ${HC_KUBECONFIG} get ns > ${data_dir}/hc.namespaces 2>&1
oc --kubeconfig ${HC_KUBECONFIG} get po -A -o wide > ${data_dir}/hc.pods 2>&1

oc --kubeconfig ${HC_KUBECONFIG} get po -n hcp-workload-0 -o yaml > ${data_dir}/hc.pods.hcp-workload-0.yaml 2>&1

oc --kubeconfig ${HC_KUBECONFIG} get crds -A -o wide > ${data_dir}/hc.crds 2>&1

# Get the HCP CRs and count of CRs
# On a broken cluster this can take too long
# oc --kubeconfig ${HC_KUBECONFIG} api-resources | grep hcp | awk '{print $1}' | xargs -I % oc --kubeconfig ${HC_KUBECONFIG} get % -A --no-headers 2>/dev/null > ${data_dir}/hc.hcp.crs
# cat ${data_dir}/hc.hcp.crs | wc -l > ${data_dir}/hc.hcp.crs.count
oc --kubeconfig ${HC_KUBECONFIG} get hcpworkloads0 -A --no-headers > ${data_dir}/hc.hcpworkloads0 2>&1
cat ${data_dir}/hc.hcpworkloads0 | wc -l > ${data_dir}/hc.hcpworkloads0.count

echo "$(date -u +%Y%m%d-%H%M%S) :: Finished Post Clean Data Collection"

# Things to show in run log
echo "$(date -u +%Y%m%d-%H%M%S) :: KAS and Etcd Restarts"
# oc --kubeconfig ${MC_KUBECONFIG} get po -n ${HC_NS} -l app=kube-apiserver -o json | jq -r '.items[] | .metadata.name as $podname | .status.containerStatuses[] | [$podname, .restartCount, .name ] | @tsv'
# oc --kubeconfig ${MC_KUBECONFIG} get po -n ${HC_NS} -l app=etcd -o json | jq -r '.items[] | .metadata.name as $podname | .status.containerStatuses[] | [$podname, .restartCount, .name ] | @tsv'
oc --kubeconfig ${MC_KUBECONFIG} get po -n ${HC_NS} -l app=kube-apiserver
oc --kubeconfig ${MC_KUBECONFIG} get po -n ${HC_NS} -l app=etcd --no-headers

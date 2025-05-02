#!/usr/bin/env bash
# Script to setup the management cluster for Hosted Control Planes isolated on the "HCP" nodes
set -e
set -o pipefail

# Add toleration to the localvolume
oc patch localvolume -n openshift-local-storage lv-worker-localstorage --type json -p '[{"op": "add", "path": "/spec/tolerations", "value": [{"key": "node-role.kubernetes.io/hcp", "value": "reserved", "effect": "NoExecute"}]}]'

# Label the Nodes for HCP
oc --kubeconfig /root/vmno/kubeconfig label no vm00006 node-role.kubernetes.io/hcp=
oc --kubeconfig /root/vmno/kubeconfig label no vm00007 node-role.kubernetes.io/hcp=
oc --kubeconfig /root/vmno/kubeconfig label no vm00008 node-role.kubernetes.io/hcp=

# Remove worker label
oc --kubeconfig /root/vmno/kubeconfig label no vm00006 node-role.kubernetes.io/worker-
oc --kubeconfig /root/vmno/kubeconfig label no vm00007 node-role.kubernetes.io/worker-
oc --kubeconfig /root/vmno/kubeconfig label no vm00008 node-role.kubernetes.io/worker-

# Apply taint to prevent pods from running on HCP nodes
oc --kubeconfig /root/vmno/kubeconfig adm taint nodes vm00006 node-role.kubernetes.io/hcp=reserved:NoExecute
oc --kubeconfig /root/vmno/kubeconfig adm taint nodes vm00007 node-role.kubernetes.io/hcp=reserved:NoExecute
oc --kubeconfig /root/vmno/kubeconfig adm taint nodes vm00008 node-role.kubernetes.io/hcp=reserved:NoExecute

# Set PV for OpenShift-Monitoring
oc --kubeconfig /root/vmno/kubeconfig apply -f mc-manifests/cluster-monitoring-config.yaml

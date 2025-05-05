#!/usr/bin/env bash
# Script to setup the hosted cluster for a test workload

# Move Ingress to vm00009 (First Node)
oc --kubeconfig /root/standard-00001.kubeconfig patch ingresscontroller -n openshift-ingress-operator default --type json -p '[{"op": "add", "path": "/spec/nodePlacement", "value": {}}]'
oc --kubeconfig /root/standard-00001.kubeconfig patch ingresscontroller -n openshift-ingress-operator default --type json -p '[{"op": "add", "path": "/spec/nodePlacement/nodeSelector", "value": {}}]'
oc --kubeconfig /root/standard-00001.kubeconfig patch ingresscontroller -n openshift-ingress-operator default --type json -p '[{"op": "add", "path": "/spec/nodePlacement/nodeSelector/matchLabels", "value": {"kubernetes.io/hostname":"vm00009"}}]'

excluded_nodes="vm00009|vm00010|vm00011"

# Add workload node-role
oc --kubeconfig /root/standard-00001.kubeconfig get no --no-headers | egrep -v "${excluded_nodes}" | awk '{print $1}' | xargs -I % oc --kubeconfig /root/standard-00001.kubeconfig label no % node-role.kubernetes.io/workload=
# Remove worker node-role
oc --kubeconfig /root/standard-00001.kubeconfig get no --no-headers | egrep -v "${excluded_nodes}" | awk '{print $1}' | xargs -I % oc --kubeconfig /root/standard-00001.kubeconfig label no % node-role.kubernetes.io/worker-
# Apply workload taint
oc --kubeconfig /root/standard-00001.kubeconfig get no --no-headers | egrep -v "${excluded_nodes}" | awk '{print $1}' | xargs -I % oc --kubeconfig /root/standard-00001.kubeconfig adm taint nodes % node-role.kubernetes.io/workload=reserved:NoExecute

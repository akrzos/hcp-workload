#!/usr/bin/env bash
# Script to setup the hosted cluster for a test workload

# Move Ingress to vm00009 (First Node)
oc --kubeconfig /root/standard-00001.kubeconfig patch ingresscontroller -n openshift-ingress-operator default --type json -p '[{"op": "add", "path": "/spec/nodePlacement", "value": {}}]'
oc --kubeconfig /root/standard-00001.kubeconfig patch ingresscontroller -n openshift-ingress-operator default --type json -p '[{"op": "add", "path": "/spec/nodePlacement/nodeSelector", "value": {}}]'
oc --kubeconfig /root/standard-00001.kubeconfig patch ingresscontroller -n openshift-ingress-operator default --type json -p '[{"op": "add", "path": "/spec/nodePlacement/nodeSelector/matchLabels", "value": {"kubernetes.io/hostname":"vm00009"}}]'

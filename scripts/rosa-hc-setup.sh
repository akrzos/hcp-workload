#!/usr/bin/env bash
# Script to setup the hosted cluster on Rosa for a test workload

oc --kubeconfig ${HC_KUBECONFIG} get no --no-headers | awk '{print $1}' | xargs -I % oc label no % node-role.kubernetes.io/workload=

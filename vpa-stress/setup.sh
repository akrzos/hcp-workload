#!/usr/bin/env bash

export KUBECONFIG=/root/vmno/kubeconfig

# Label the worker nodes each for a different workload
oc label no vm00004 node-role.kubernetes.io/workload1=
oc label no vm00005 node-role.kubernetes.io/workload2=
oc label no vm00006 node-role.kubernetes.io/workload3=
oc label no vm00007 node-role.kubernetes.io/workload4=
oc label no vm00008 node-role.kubernetes.io/workload5=
oc label no vm00009 node-role.kubernetes.io/workload6=

# Create the vpa-stress namespaces and deployments
oc create -f deployments/

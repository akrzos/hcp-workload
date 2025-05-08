#!/usr/bin/env bash
# For testing the workload config file
set -e
set -o pipefail

# Start Timestamp
ts="$(date -u +%Y%m%d-%H%M%S)"

# Workload Job Config
export ITERATIONS=1
# kube-burner-ocp automatically obtains prometheus URL and token
# export PROM_URL=https://$(oc -n openshift-monitoring get route prometheus-k8s -oyaml | grep host: | head -1 | awk '{ print $2 }')
# export PROM_TOKEN=$(oc -n openshift-monitoring create token prometheus-k8s)
if [ -z ${ES_SERVER} ]; then export ES_SERVER=""; fi
if [ -z ${ES_INDEX} ]; then export ES_INDEX=""; fi
export LOCAL_INDEXING=true
export METRICS_DIRECTORY="results/${ts}-testrun-${ITERATIONS}"
export JOB_PAUSE_TIME="15s"
export QPS=40
export BURST=80

# Objects Config
export CRDS=50
export CRS=1
export CR_SIZE=1024
export SERVER_DEPLOYMENTS=1
export CLIENT_DEPLOYMENTS=1
export CONFIGMAPS=1
export CM_KEY_COUNT=1
export CM_VALUE_SIZE=512
export SECRETS=1
export SECRET_KEY_COUNT=1
export SECRET_VALUE_SIZE=512
export SERVICES=1
export POD_COUNT=1
export CONTAINER_COUNT=1
export LABEL_COUNT=1
export ENV_ADD_VAR_COUNT=1
# Env var size in bytes
# 1024 - 1KiB (1024 Bytes), 102400 - 100KiB Works
# 128KiB (131072), 256KiB (262144), 512KiB (524288), 1MiB(1048576), All Too Large
export ENV_ADD_VAR_SIZE=1024
# export ENV_ADD_VAR_SIZE=102400
# export ENV_ADD_VAR_SIZE=1048576

log_file="${METRICS_DIRECTORY}.log"

time kube-burner-ocp --local-indexing --qps ${QPS} --burst ${BURST} init -c hcp-workload/job-workload.yml | tee ${log_file}
# time kube-burner-ocp --local-indexing --qps ${QPS} --burst ${BURST} init -c hcp-workload/job-workload.yml --log-level debug | tee ${log_file}

#!/usr/bin/env bash
# Ramp count of the CRs test
set -e
set -o pipefail

# Start Timestamp
ts="$(date -u +%Y%m%d-%H%M%S)"

# Workload Job Config
export ITERATIONS=10
# kube-burner-ocp automatically obtains prometheus URL and token
# export PROM_URL=https://$(oc -n openshift-monitoring get route prometheus-k8s -oyaml | grep host: | head -1 | awk '{ print $2 }')
# export PROM_TOKEN=$(oc -n openshift-monitoring create token prometheus-k8s)
if [ -z ${ES_SERVER} ]; then export ES_SERVER=""; fi
if [ -z ${ES_INDEX} ]; then export ES_INDEX=""; fi
export LOCAL_INDEXING=true
export JOB_PAUSE_TIME="3m"
export QPS=40
export BURST=80

# Objects Config
export CRDS=50
export CR_SIZE=1024
export SERVER_DEPLOYMENTS=2
export CLIENT_DEPLOYMENTS=2
export CONFIGMAPS=5
export CM_KEY_COUNT=10
export CM_VALUE_SIZE=1024
export SECRETS=5
export SECRET_KEY_COUNT=10
export SECRET_VALUE_SIZE=1024
export SERVICES=2
export POD_COUNT=4
export CONTAINER_COUNT=2
export LABEL_COUNT=5
export ENV_ADD_VAR_COUNT=5
# Env var size in bytes
# 1024 - 1KiB (1024 Bytes), 102400 - 100KiB Works
# 128KiB (131072), 256KiB (262144), 512KiB (524288), 1MiB(1048576), All Too Large
export ENV_ADD_VAR_SIZE=1024
# export ENV_ADD_VAR_SIZE=1024
# export ENV_ADD_VAR_SIZE=102400
# export ENV_ADD_VAR_SIZE=1048576

# Range of CR Counts
cr_count=("10" "100" "1000" "2000")

for i in "${!cr_count[@]}"; do
  export CRS=${cr_count[$i]}
  echo "Running Test: $i, CRDs: ${CRDS}, CRs: ${CRS}, ${CR_SIZE}"
  export METRICS_DIRECTORY="results/${ts}-ramp-cr-count-${i}-${CRS}"
  log_file="${METRICS_DIRECTORY}.log"
  time kube-burner-ocp --local-indexing --qps ${QPS} --burst ${BURST} init -c hcp-workload/job-workload.yml | tee ${log_file}
  # time kube-burner-ocp init -c hcp-workload/job-workload.yml --log-level debug | tee ${log_file}
done

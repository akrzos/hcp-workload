#!/usr/bin/env bash
# Ramp ENV Var Sizes
set -e
set -o pipefail

# Start Timestamp
ts="$(date -u +%Y%m%d-%H%M%S)"

timeout=30m

# Workload Job Config
export ITERATIONS=5
# Although kube-burner-ocp automatically obtains prometheus URL and token
# it is unclear why that is not working correctly
export PROM_URL=https://$(oc -n openshift-monitoring get route prometheus-k8s -oyaml | grep host: | head -1 | awk '{ print $2 }')
export PROM_TOKEN=$(oc -n openshift-monitoring create token prometheus-k8s)
if [ -z ${ES_SERVER} ]; then export ES_SERVER=""; fi
if [ -z ${ES_INDEX} ]; then export ES_INDEX=""; fi
export LOCAL_INDEXING=true
export JOB_PAUSE_TIME="15s"
export QPS=40
export BURST=80

# Objects Config
export CRDS=0
export CRS=0
export CR_SIZE=1024
export SERVER_DEPLOYMENTS=1
export CLIENT_DEPLOYMENTS=0
export CONFIGMAPS=0
export CM_KEY_COUNT=1
export CM_VALUE_SIZE=1024
export SECRETS=0
export SECRET_KEY_COUNT=1
export SECRET_VALUE_SIZE=1024
export SERVICES=0
export POD_COUNT=1
export CONTAINER_COUNT=1
export LABEL_COUNT=0
export ENV_ADD_VAR_COUNT=1
# export ENV_ADD_VAR_SIZE=1024 # (Ramped in a variable below)

# Range of ENV Var Sizes
env_var_sizes=("1024" "2048" "4096" "8192" "16384" "32768" "65536" "131072" "262144" "524288" "1048576" "2097152" "4194304" "8388608" "16777216" "33554432")
# 131072 results in "exec container process `/dist/main`: Argument list too long"

for i in "${!env_var_sizes[@]}"; do
  export ENV_ADD_VAR_SIZE=${env_var_sizes[$i]}
  echo "Running Test: $i, Env Var Size: ${ENV_ADD_VAR_SIZE}"
  export METRICS_DIRECTORY="results/${ts}-ramp-env-size-${i}-${ENV_ADD_VAR_SIZE}"
  log_file="${METRICS_DIRECTORY}.log"
  time kube-burner-ocp --local-indexing --qps ${QPS} --burst ${BURST} --timeout ${timeout} --enable-file-logging=False init -c hcp-workload/job-workload.yml 2>&1 | tee ${log_file}
  # time kube-burner-ocp --local-indexing --qps ${QPS} --burst ${BURST} --timeout ${timeout} --enable-file-logging=False init -c hcp-workload/job-workload.yml --log-level debug 2>&1 | tee ${log_file}
done

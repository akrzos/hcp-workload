#!/usr/bin/env bash
# Workload rate test
set -e
set -o pipefail

# Start Timestamp
ts="$(date -u +%Y%m%d-%H%M%S)"

# checkhealth=true
checkhealth=false

timeout=30m

# Workload Job Config
export ITERATIONS=10
# Although kube-burner-ocp automatically obtains prometheus URL and token
# it is unclear why that is not working correctly
export PROM_URL=https://$(oc -n openshift-monitoring get route prometheus-k8s -oyaml | grep host: | head -1 | awk '{ print $2 }')
export PROM_TOKEN=$(oc -n openshift-monitoring create token prometheus-k8s)
if [ -z ${ES_SERVER} ]; then export ES_SERVER=""; fi
if [ -z ${ES_INDEX} ]; then export ES_INDEX=""; fi
export LOCAL_INDEXING=true
export JOB_PAUSE_TIME="3m"
# export QPS=40 # (Ramped in a variables below)
# export BURST=80 # (Ramped in a variables below)

# Objects Config
export CRDS=50
export CRS=5
export CR_SIZE=1024
# export CR_SIZE=1048576
export SERVER_DEPLOYMENTS=2
export CLIENT_DEPLOYMENTS=2
export CONFIGMAPS=5
export CM_KEY_COUNT=10
export CM_VALUE_SIZE=1024
export SECRETS=5
export SECRET_KEY_COUNT=10
export SECRET_VALUE_SIZE=1024
export SERVICES=2
export POD_COUNT=2
export CONTAINER_COUNT=2
export LABEL_COUNT=5
export ENV_ADD_VAR_COUNT=5
export ENV_ADD_VAR_SIZE=1024

# Range of QPS and Bursts
# First keep QPS and Burst equal
qps=("10" "20" "40" "80" "100" "150" "200" "250" "300" "350" "400")
burst=("10" "20" "40" "80" "100" "150" "200" "250" "300" "350" "400")

for i in "${!qps[@]}"; do
  export QPS=${qps[$i]}
  export BURST=${burst[$i]}
  echo "Running Test: $i, QPS: ${QPS}, BURST: ${BURST}"
  export METRICS_DIRECTORY="results/${ts}-ramp-qps-${i}-${QPS}-${BURST}"
  log_file="${METRICS_DIRECTORY}.log"
  time kube-burner-ocp --check-health=${checkhealth} --local-indexing --qps ${QPS} --burst ${BURST} --timeout ${timeout} --enable-file-logging=False init -c hcp-workload/job-workload.yml | tee ${log_file}
  # time kube-burner-ocp --check-health=${checkhealth} --local-indexing --qps ${QPS} --burst ${BURST} --timeout ${timeout} --enable-file-logging=False init -c hcp-workload/job-workload.yml --log-level debug | tee ${log_file}
done

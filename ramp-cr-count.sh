#!/usr/bin/env bash
# Ramp count of the CRs test
set -e
set -o pipefail

# Start Timestamp
ts="$(date -u +%Y%m%d-%H%M%S)"

# checkhealth=true
checkhealth=false

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
export QPS=100
export BURST=200

# Objects Config
export CRDS=1
# export CRS=0 # (Ramped in a variable below)
# export CR_SIZE=1048576 # (Adjust according to counts of CRs Tested)
export SERVER_DEPLOYMENTS=0
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
export ENV_ADD_VAR_SIZE=1024

# Range of CR Counts
# 1MiB seems to break with etcd around 1000
# export CR_SIZE=1048576
# cr_count=("10" "100" "250" "500" "1000" "2000")
# 512KiB
# export CR_SIZE=524288
# cr_count=("20" "200" "500" "1000" "2000" "4000")
# 256KiB
# export CR_SIZE=262144
# cr_count=("40" "400" "1000" "2000" "4000" "8000")
# 128KiB
export CR_SIZE=131072
cr_count=("80" "800" "2000" "4000" "8000" "16000")

for i in "${!cr_count[@]}"; do
  export CRS=${cr_count[$i]}
  echo "Running Test: $i, CRDs: ${CRDS}, CRs: ${CRS}, CR Size: ${CR_SIZE}"
  export METRICS_DIRECTORY="results/${ts}-ramp-cr-count-${i}-${CRS}"
  log_file="${METRICS_DIRECTORY}.log"
  time kube-burner-ocp --check-health=${checkhealth} --local-indexing --qps ${QPS} --burst ${BURST} --timeout ${timeout} init -c hcp-workload/job-workload.yml | tee ${log_file}
  # time kube-burner-ocp --check-health=${checkhealth} --local-indexing --qps ${QPS} --burst ${BURST} --timeout ${timeout} init -c hcp-workload/job-workload.yml --log-level debug | tee ${log_file}
done

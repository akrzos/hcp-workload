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
export QPS=50
export BURST=100

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


cr_sizes=()
cr_counts=()

# Range of CR Size + CR Counts
# 1024KiB / 1MiB
cr_sizes+=("1048576" "1048576" "1048576" "1048576")
cr_counts+=("10" "100" "250" "500")
# 512KiB
cr_sizes+=("524288" "524288" "524288" "524288")
cr_counts+=("20" "200" "500" "1000")
# 256KiB
cr_sizes+=("262144" "262144" "262144" "262144")
cr_counts+=("40" "400" "1000" "2000")
# 128KiB
cr_sizes+=("131072" "131072" "131072" "131072")
cr_counts+=("80" "800" "2000" "4000")
# 64KiB
cr_sizes+=("65536" "65536" "65536" "65536")
cr_counts+=("160" "1600" "4000" "8000")

for i in "${!cr_counts[@]}"; do
  export CRS=${cr_counts[$i]}
  export CR_SIZE=${cr_sizes[$i]}
  export METRICS_DIRECTORY="results/${ts}-ramp-cr-count/${i}-${CRS}-${CR_SIZE}"
  data_dir="${METRICS_DIRECTORY}-data"
  mkdir -p "${METRICS_DIRECTORY}"
  mkdir -p "${data_dir}"
  kb_log_file="${METRICS_DIRECTORY}-kb.log"
  data_log_file="${METRICS_DIRECTORY}-data.log"
  echo "$(date -u +%Y%m%d-%H%M%S) :: Running Test: $i, CRDs: ${CRDS}, CRs: ${CRS}, CR Size: ${CR_SIZE}" | tee -a "${data_log_file}"
  echo "$(date -u +%Y%m%d-%H%M%S) :: Start KB Time: $(date -u)" | tee -a "${data_log_file}"
  time kube-burner-ocp --check-health=${checkhealth} --local-indexing --qps ${QPS} --burst ${BURST} --timeout ${timeout} init -c hcp-workload/job-workload.yml | tee ${kb_log_file}
  # time kube-burner-ocp --check-health=${checkhealth} --local-indexing --qps ${QPS} --burst ${BURST} --timeout ${timeout} init -c hcp-workload/job-workload.yml --log-level debug | tee ${kb_log_file}
  echo "$(date -u +%Y%m%d-%H%M%S) :: End KB Time: $(date -u)" | tee -a "${data_log_file}"
  ./collect-data.sh ${data_dir} 2>&1 | tee -a ${data_log_file}
  echo "$(date -u +%Y%m%d-%H%M%S) :: Sleep 120s between tests" | tee -a "${data_log_file}"
  sleep 120
  echo "-----------------------------------------"
done

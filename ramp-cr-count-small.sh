#!/usr/bin/env bash
# Ramp count of Small CRs
# set -e
set -o pipefail

# Start Timestamp
ts="$(date -u +%Y%m%d-%H%M%S)"

# checkhealth=true
checkhealth=false

timeout=45m

# Workload Job Config
export ITERATIONS=40
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
# export CR_SIZE=32768 # (Adjust according to counts of CRs Tested)
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
# 32KiB
cr_sizes+=("32768" "32768" "32768" "32768")
cr_counts+=("40" "400" "1000" "2000")
# 16KiB
cr_sizes+=("16384" "16384" "16384" "16384")
cr_counts+=("80" "800" "2000" "4000")
# 8KiB
cr_sizes+=("8192" "8192" "8192" "8192")
cr_counts+=("160" "1600" "4000" "8000")
# 4KiB
cr_sizes+=("4096" "4096" "4096" "4096")
cr_counts+=("320" "3200" "8000" "16000")
# 2KiB
cr_sizes+=("2048" "2048" "2048" "2048")
cr_counts+=("640" "6400" "16000" "32000")
# 1KiB
cr_sizes+=("1024" "1024" "1024" "1024")
cr_counts+=("1280" "12800" "32000" "64000")

test_dir="results/${ts}-ramp-small-cr-counts"
run_log_file="${test_dir}/run.log"
for i in "${!cr_counts[@]}"; do
  export CRS=${cr_counts[$i]}
  export CR_SIZE=${cr_sizes[$i]}
  export METRICS_DIRECTORY="${test_dir}/${i}-${CRS}-${CR_SIZE}"
  kb_log_file="${METRICS_DIRECTORY}-kb.log"
  data_dir="${METRICS_DIRECTORY}-data"
  mkdir -p "${METRICS_DIRECTORY}"
  mkdir -p "${data_dir}"
  echo "$(date -u +%Y%m%d-%H%M%S) :: Running Test: $i, CRDs: ${CRDS}, CRs: ${CRS}, CR Size: ${CR_SIZE}" | tee -a "${run_log_file}"
  KB_START_TIME=$(date +%s)
  echo "$(date -u +%Y%m%d-%H%M%S) :: Start KB Time: ${KB_START_TIME}" | tee -a "${run_log_file}"
  time kube-burner-ocp --check-health=${checkhealth} --local-indexing --qps ${QPS} --burst ${BURST} --timeout ${timeout} --enable-file-logging=False init -c hcp-workload/job-workload.yml | tee ${kb_log_file}
  # time kube-burner-ocp --check-health=${checkhealth} --local-indexing --qps ${QPS} --burst ${BURST} --timeout ${timeout} --enable-file-logging=False init -c hcp-workload/job-workload.yml --log-level debug | tee ${kb_log_file}
  kb_rc=$?
  echo "$(date -u +%Y%m%d-%H%M%S) :: kube-burner, RC: ${kb_rc}" | tee -a "${run_log_file}"
  KB_END_TIME=$(date +%s)
  echo "$(date -u +%Y%m%d-%H%M%S) :: End KB Time: ${KB_END_TIME}" | tee -a "${run_log_file}"
  ./collect-data.sh ${data_dir} ${KB_START_TIME} ${KB_END_TIME} 2>&1 | tee -a ${run_log_file}
  echo "$(date -u +%Y%m%d-%H%M%S) :: Sleep 120s between tests" | tee -a "${run_log_file}"
  sleep 120
  echo "-----------------------------------------"  | tee -a "${run_log_file}"

  # Exit so we know last test failed kube-burner (Disabled since can/will prevent script from completing run)
  # if [ $kb_rc -ne 0 ]; then
  #   echo "$(date -u +%Y%m%d-%H%M%S) :: Last test failed kube-burner, RC: ${kb_rc}" | tee -a "${run_log_file}"
  #   exit 1
  # fi
done

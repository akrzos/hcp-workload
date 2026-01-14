#!/usr/bin/env bash
# Step count of ConfigMaps and query memory usage each step
# set -e
set -o pipefail

# Start Timestamp
ts="$(date -u +%Y%m%d-%H%M%S)"

timeout=3h

# Workload Job Config
export ITERATIONS=10
# Although kube-burner-ocp automatically obtains prometheus URL and token
# it is unclear why that is not working correctly
export PROM_URL=https://$(oc -n openshift-monitoring get route prometheus-k8s -oyaml | grep host: | head -1 | awk '{ print $2 }')
export PROM_TOKEN=$(oc -n openshift-monitoring create token prometheus-k8s)
if [ -z ${ES_SERVER} ]; then export ES_SERVER=""; fi
if [ -z ${ES_INDEX} ]; then export ES_INDEX=""; fi
export LOCAL_INDEXING=true
export JOB_PAUSE_TIME="30m"
# export QPS=250
export QPS=500
export BURST=100

# Objects Config
export CONFIGMAPS=10000
export CM_KEY_COUNT=2
export CM_VALUE_SIZE=1024
export SECRETS=0
export SECRET_KEY_COUNT=0
export SECRET_VALUE_SIZE=1024

test_dir="results/${ts}-cm-count"
data_pre_run_dir="${test_dir}/pre-run-data"
run_log_file="${test_dir}/run.log"
echo "$(date -u +%Y%m%d-%H%M%S) :: Collecting Pre-Run Data" | tee -a "${run_log_file}"
KB_END_TIME=$(date +%s)
KB_START_TIME=$((KB_END_TIME - 600))
./scripts/metrics.sh ${KB_START_TIME} ${KB_END_TIME} | tee -a ${run_log_file}
./collect-pre-run-data.sh ${data_pre_run_dir}
for i in {1..10}; do
  export CM_PREFIX=server-${i}
  export METRICS_DIRECTORY="${test_dir}/cm-step-${i}"
  kb_log_file="${METRICS_DIRECTORY}-kb.log"
  data_post_run_dir="${METRICS_DIRECTORY}-post-run-data"
  mkdir -p "${METRICS_DIRECTORY}" "${data_post_run_dir}"
  echo "$(date -u +%Y%m%d-%H%M%S) :: Running Test: $i" | tee -a "${run_log_file}"
  KB_START_TIME=$(date +%s)
  echo "$(date -u +%Y%m%d-%H%M%S) :: Start KB Time: ${KB_START_TIME}" | tee -a "${run_log_file}"
  time kube-burner-ocp --local-indexing --qps ${QPS} --burst ${BURST} --timeout ${timeout} --enable-file-logging=False init -c hcp-workload/job-cm.yml 2>&1 | tee ${kb_log_file}
  kb_rc=$?
  echo "$(date -u +%Y%m%d-%H%M%S) :: kube-burner, RC: ${kb_rc}" | tee -a "${run_log_file}"
  KB_END_TIME=$(date +%s)
  KB_RUNTIME=$(($KB_END_TIME - $KB_START_TIME))
  echo "$(date -u +%Y%m%d-%H%M%S) :: Test Time (Seconds) : ${KB_RUNTIME}" | tee -a "${run_log_file}"
  echo "$(date -u +%Y%m%d-%H%M%S) :: End KB Time: ${KB_END_TIME}" | tee -a "${run_log_file}"
  ./collect-post-run-data.sh ${data_post_run_dir} ${KB_START_TIME} ${KB_END_TIME} 2>&1 | tee -a ${run_log_file}
done



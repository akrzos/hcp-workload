#!/usr/bin/env bash
# Ramp count of ConfigMaps on a cluster
# 80,000-90,000 CMs (Each with 2 keys of 1KiB) * 10 Namespaces will trigger KAS OOM on m5.xlarge serving nodes (500 QPS)
# 50,000 CMs (Each with 8 keys of 1KiB) * 10 Namespaces will trigger KAS OOM on m5.xlarge serving nodes (250 QPS)
# 30,000 CMs (Each with 16 keys of 1KiB) * 10 Namespaces will trigger KAS OOM on m5.xlarge serving nodes (250 QPS)
# set -e
set -o pipefail

# Start Timestamp
ts="$(date -u +%Y%m%d-%H%M%S)"

timeout=2h

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
# export QPS=250
export QPS=500
export BURST=100

# Objects Config
export CRDS=0
export CRS=0
export CR_SIZE=0
export SERVER_DEPLOYMENTS=0
export CLIENT_DEPLOYMENTS=0
# export CONFIGMAPS=1 # (Ramped in a variable below)
export CM_PREFIX=server
export CM_KEY_COUNT=2
export CM_VALUE_SIZE=1024
export SECRETS=0
export SECRET_KEY_COUNT=0
export SECRET_VALUE_SIZE=1024
export SERVICES=0
export POD_COUNT=0
export CONTAINER_COUNT=0
export LABEL_COUNT=0
export ENV_ADD_VAR_COUNT=0
export ENV_ADD_VAR_SIZE=1024

# Watcher deployment configuration
export WATCHERS=0
export WATCHER_POD_REPLICAS=0
export WATCHER_CONTAINER_COUNT=0
export SECRET_KC=$(cat ${HC_KUBECONFIG} | base64 -w 0)

cm_counts=()

# Range of Configmap counts
cm_counts+=("10000" "20000" "30000" "40000" "50000" "60000" "70000" "80000" "90000" "100000")
# cm_counts+=("80000" "90000" "100000" "110000" "120000" "130000" "140000" "150000")
# cm_counts+=("10000" "20000" "30000" "40000" "50000")

test_dir="results/${ts}-cm-count"
data_pre_run_dir="${test_dir}/pre-run-data"
run_log_file="${test_dir}/run.log"
mkdir -p "${test_dir}" "${data_pre_run_dir}"
./collect-pre-run-data.sh ${data_pre_run_dir} | tee -a ${run_log_file}

for i in "${!cm_counts[@]}"; do
  export CONFIGMAPS=${cm_counts[$i]}
  export METRICS_DIRECTORY="${test_dir}/${i}-${CONFIGMAPS}"
  kb_log_file="${METRICS_DIRECTORY}-kb.log"
  kb_clean_log_file="${METRICS_DIRECTORY}-kb-clean.log"
  data_post_run_dir="${METRICS_DIRECTORY}-post-run-data"
  data_post_clean_dir="${METRICS_DIRECTORY}-post-clean-data"
  mkdir -p "${METRICS_DIRECTORY}" "${data_post_run_dir}" "${data_post_clean_dir}"
  echo "$(date -u +%Y%m%d-%H%M%S) :: Running Test: $i, CONFIGMAPS: ${CONFIGMAPS}" | tee -a "${run_log_file}"
  KB_START_TIME=$(date +%s)
  echo "$(date -u +%Y%m%d-%H%M%S) :: Start KB Time: ${KB_START_TIME}" | tee -a "${run_log_file}"
  time kube-burner-ocp --local-indexing --qps ${QPS} --burst ${BURST} --timeout ${timeout} --enable-file-logging=False init -c hcp-workload/job-cm.yml 2>&1 | tee ${kb_log_file}
  # time kube-burner-ocp --local-indexing --qps ${QPS} --burst ${BURST} --timeout ${timeout} --enable-file-logging=False init -c hcp-workload/job-cm.yml --log-level debug 2>&1 | tee ${kb_log_file}
  kb_rc=$?
  echo "$(date -u +%Y%m%d-%H%M%S) :: kube-burner, RC: ${kb_rc}" | tee -a "${run_log_file}"
  KB_END_TIME=$(date +%s)
  KB_RUNTIME=$(($KB_END_TIME - $KB_START_TIME))
  echo "$(date -u +%Y%m%d-%H%M%S) :: Test Time (Seconds) : ${KB_RUNTIME}" | tee -a "${run_log_file}"
  echo "$(date -u +%Y%m%d-%H%M%S) :: End KB Time: ${KB_END_TIME}" | tee -a "${run_log_file}"
  ./collect-post-run-data.sh ${data_post_run_dir} ${KB_START_TIME} ${KB_END_TIME} 2>&1 | tee -a ${run_log_file}
  echo "$(date -u +%Y%m%d-%H%M%S) :: Performing Cleanup" | tee -a "${run_log_file}"
  export CLEANUP_CRDS=false
  KB_START_CLEAN_TIME=$(date +%s)
  time kube-burner-ocp --ignore-health-check --enable-file-logging=False init -c hcp-workload/job-cleanup.yml 2>&1 | tee ${kb_clean_log_file}
  kb_rc=$?
  echo "$(date -u +%Y%m%d-%H%M%S) :: kube-burner cleanup, RC: ${kb_rc}" | tee -a "${run_log_file}"
  KB_END_CLEAN_TIME=$(date +%s)
  KB_CLEAN_TIME=$(($KB_END_CLEAN_TIME - $KB_START_CLEAN_TIME))
  echo "$(date -u +%Y%m%d-%H%M%S) :: Clean Time (Seconds) : ${KB_CLEAN_TIME}" | tee -a "${run_log_file}"
  ./collect-post-clean-data.sh ${data_post_clean_dir} | tee -a "${run_log_file}"
  echo "$(date -u +%Y%m%d-%H%M%S) :: Sleep 120s between tests" | tee -a "${run_log_file}"
  sleep 120
  echo "-----------------------------------------"  | tee -a "${run_log_file}"

  # Exit so we know last test failed kube-burner (Disabled since can/will prevent script from completing run)
  # if [ $kb_rc -ne 0 ]; then
  #   echo "$(date -u +%Y%m%d-%H%M%S) :: Last test failed kube-burner, RC: ${kb_rc}" | tee -a "${run_log_file}"
  #   exit 1
  # fi
done

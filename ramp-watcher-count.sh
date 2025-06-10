#!/usr/bin/env bash
# Ramp count of watchers in the cluster
# 250 CRs (1024KiB/1MiB Ea) * 10 Namespaces will bring HCP down with 40 watcher pods with 2 watcher containers each (80 total containers/watchers)
# 200 CRs (1024KiB/1MiB Ea) * 10 Namespaces will bring HCP down with 60 watcher pods with 2 watcher containers each (120 total containers/watchers)
# 125 CRs (1024KiB/1MiB Ea) * 10 Namespaces will bring HCP down with 120 watcher pods with 2 watcher containers each (240 total containers/watchers)
# set -e
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
export JOB_PAUSE_TIME="5m"
export QPS=50
export BURST=100

# Objects Config
export CRDS=1
export CRS=250
export CR_SIZE=1048576
export SERVER_DEPLOYMENTS=1
export CLIENT_DEPLOYMENTS=1
export CONFIGMAPS=1
export CM_KEY_COUNT=1
export CM_VALUE_SIZE=1024
export SECRETS=1
export SECRET_KEY_COUNT=1
export SECRET_VALUE_SIZE=1024
export SERVICES=1
export POD_COUNT=1
export CONTAINER_COUNT=1
export LABEL_COUNT=1
export ENV_ADD_VAR_COUNT=2
export ENV_ADD_VAR_SIZE=1024

# Watcher deployment configuration
# export WATCHERS=1 # (Ramped in a variable below)
export WATCHER_POD_REPLICAS=1
export WATCHER_CONTAINER_COUNT=2
export SECRET_KC=$(cat ${HC_KUBECONFIG} | base64 -w 0)

watchers_counts=()

# Range of Watcher Replicas
watchers_counts+=("2" "4" "6" "8" "10" "12")

test_dir="results/${ts}-watchers"
run_log_file="${test_dir}/run.log"
for i in "${!watchers_counts[@]}"; do
  export WATCHERS=${watchers_counts[$i]}
  export METRICS_DIRECTORY="${test_dir}/${i}-${WATCHERS}"
  kb_log_file="${METRICS_DIRECTORY}-kb.log"
  kb_clean_log_file="${METRICS_DIRECTORY}-kb-clean.log"
  data_post_run_dir="${METRICS_DIRECTORY}-post-run-data"
  data_post_clean_dir="${METRICS_DIRECTORY}-post-clean-data"
  mkdir -p "${METRICS_DIRECTORY}" "${data_post_run_dir}" "${data_post_clean_dir}"
  echo "$(date -u +%Y%m%d-%H%M%S) :: Running Test: $i, WATCHERS: ${WATCHERS}" | tee -a "${run_log_file}"
  KB_START_TIME=$(date +%s)
  echo "$(date -u +%Y%m%d-%H%M%S) :: Start KB Time: ${KB_START_TIME}" | tee -a "${run_log_file}"
  time kube-burner-ocp --check-health=${checkhealth} --local-indexing --qps ${QPS} --burst ${BURST} --timeout ${timeout} --enable-file-logging=False init -c hcp-workload/job-workload.yml 2>&1 | tee ${kb_log_file}
  # time kube-burner-ocp --check-health=${checkhealth} --local-indexing --qps ${QPS} --burst ${BURST} --timeout ${timeout} --enable-file-logging=False init -c hcp-workload/job-workload.yml --log-level debug 2>&1 | tee ${kb_log_file}
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
  time kube-burner-ocp --check-health=false --enable-file-logging=False init -c hcp-workload/job-cleanup.yml 2>&1 | tee ${kb_clean_log_file}
  kb_rc=$?
  echo "$(date -u +%Y%m%d-%H%M%S) :: kube-burner cleanup, RC: ${kb_rc}" | tee -a "${run_log_file}"
  KB_END_CLEAN_TIME=$(date +%s)
  KB_CLEAN_TIME=$(($KB_END_CLEAN_TIME - $KB_START_CLEAN_TIME))
  echo "$(date -u +%Y%m%d-%H%M%S) :: Clean Time (Seconds) : ${KB_CLEAN_TIME}" | tee -a "${run_log_file}"
  ./collect-post-clean-data.sh ${data_post_clean_dir}
  echo "$(date -u +%Y%m%d-%H%M%S) :: Sleep 120s between tests" | tee -a "${run_log_file}"
  sleep 120
  echo "-----------------------------------------"  | tee -a "${run_log_file}"

  # Exit so we know last test failed kube-burner (Disabled since can/will prevent script from completing run)
  # if [ $kb_rc -ne 0 ]; then
  #   echo "$(date -u +%Y%m%d-%H%M%S) :: Last test failed kube-burner, RC: ${kb_rc}" | tee -a "${run_log_file}"
  #   exit 1
  # fi
done

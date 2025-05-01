#!/usr/bin/env bash
set -e
set -o pipefail

# Start Timestamp
ts="$(date -u +%Y%m%d-%H%M%S)"

# Workload Job Config
export ITERATIONS=100
export JOB_PAUSE_TIME="3m"

# Objects Config
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
# Env var size in bytes
# 1024 - 1KiB (1024 Bytes), 102400 - 100KiB Works
# 128KiB (131072), 256KiB (262144), 512KiB (524288), 1MiB(1048576), All Too Large
export ENV_ADD_VAR_SIZE=1024
# export ENV_ADD_VAR_SIZE=1024
# export ENV_ADD_VAR_SIZE=102400
# export ENV_ADD_VAR_SIZE=1048576

# Range of QPS and Bursts
qps=("10" "20" "40" "80")
burst=("20" "40" "80" "160")

for i in "${!qps[@]}"; do
  export QPS=${qps[$i]}
  export BURST=${burst[$i]}
  echo "Running Test: $i, QPS: ${QPS}, BURST: ${BURST}"
  export METRICS_DIRECTORY="rate-test-${QPS}-${BURST}-${ts}"
  log_file="rate-test-${QPS}-${BURST}-${ts}.log"
  time kube-burner init -c hcp-workload.yml | tee ${log_file}
  # time kube-burner init -c hcp-workload.yml --log-level debug
done

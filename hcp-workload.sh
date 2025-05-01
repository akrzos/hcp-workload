#!/usr/bin/env bash
set -e
set -o pipefail

# Workload Job Config
export ITERATIONS=1
export METRICS_DIRECTORY="testrun"
export JOB_PAUSE_TIME="5m"
export QPS=10
export BURST=20

# Objects Config
export SERVER_DEPLOYMENTS=1
export CLIENT_DEPLOYMENTS=1
export CONFIGMAPS=1
export CM_KEY_COUNT=1
export CM_VALUE_SIZE=512
export SECRETS=1
export SECRET_KEY_COUNT=1
export SECRET_VALUE_SIZE=512
export SERVICES=1
export POD_COUNT=1
export CONTAINER_COUNT=1

export LABEL_COUNT=1


export ENV_ADD_VAR_COUNT=1
# Env var size in bytes
# 1024 - 1KiB (1024 Bytes), 102400 - 100KiB Works
# 128KiB (131072), 256KiB (262144), 512KiB (524288), 1MiB(1048576), All Too Large
export ENV_ADD_VAR_SIZE=64
# export ENV_ADD_VAR_SIZE=1024
# export ENV_ADD_VAR_SIZE=102400
# export ENV_ADD_VAR_SIZE=1048576

time kube-burner init -c hcp-workload.yml
# time kube-burner init -c hcp-workload.yml --log-level debug

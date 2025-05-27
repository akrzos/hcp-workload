#!/usr/bin/env bash
# Creates the initial CRDs on the cluster and CR templates for kube-burner-ocp to use in follow on workload
set -e
set -o pipefail

# Start Timestamp
ts="$(date -u +%Y%m%d-%H%M%S)"

# checkhealth=true
checkhealth=false

# Each Iteration creates a CRD (HcpWorkload$Iteration) starting from 0
export CRDS=50

# Setting a high QPS/Burst on additional runs can cause conflicts
# between cleanup and creating the initial CRDs
export QPS=5
export BURST=5

log_file="results/${ts}-crds-${CRDS}.log"

# Generate the CR Templates for use by workload jobs that create CRs
for i in $(seq 0 $CRDS); do
  echo "$(date -u +%Y%m%d-%H%M%S) :: Generating hcp-workload/cr/hcpworkload${i}.yml" | tee -a ${log_file}
  index=$i envsubst < hcp-workload/cr-hcpworkload.yml.tmpl > hcp-workload/cr/hcpworkload${i}.yml
done
echo "$(date -u +%Y%m%d-%H%M%S) :: Completed adding ${ITERATIONS} CRDs and templated CRs" | tee -a ${log_file}

time kube-burner-ocp --check-health=${checkhealth} --qps ${QPS} --burst ${BURST} --enable-file-logging=False init -c hcp-workload/job-crd.yml | tee ${log_file}
# time kube-burner-ocp --check-health=${checkhealth} --qps ${QPS} --burst ${BURST} --enable-file-logging=False init -c hcp-workload/job-crd.yml --log-level debug | tee ${log_file}

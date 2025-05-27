#!/usr/bin/env bash
# Cleans up leftover hcp-workload
set -e
set -o pipefail

# Do not cleanup CRDS
export CLEANUP_CRDS=false

time kube-burner-ocp --check-health=false --enable-file-logging=False init -c hcp-workload/job-cleanup.yml

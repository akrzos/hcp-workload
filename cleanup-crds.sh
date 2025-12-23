#!/usr/bin/env bash
# Cleans up leftover hcp-workload
set -e
set -o pipefail

# Clean up CRDS
export CLEANUP_CRDS=true

time kube-burner-ocp --ignore-health-check --enable-file-logging=False init -c hcp-workload/job-cleanup.yml

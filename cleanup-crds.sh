#!/usr/bin/env bash
# Cleans up leftover hcp-workload
set -e
set -o pipefail

# Clean up CRDS
export CLEANUP_CRDS=true

time kube-burner-ocp --check-health=false init -c hcp-workload/job-cleanup.yml

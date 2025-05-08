#!/usr/bin/env bash
# Cleans up leftover hcp-workload
set -e
set -o pipefail

time kube-burner-ocp init -c hcp-workload/job-cleanup.yml

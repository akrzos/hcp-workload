#!/usr/bin/env bash
# Cleans up leftover hcp-workload
set -e
set -o pipefail

cd results/
time kube-burner init -c ../hcp-workload/job-cleanup.yml
cd ..

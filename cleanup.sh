#!/usr/bin/env bash
set -e
set -o pipefail

cd results/
time kube-burner init -c ../hcp-workload/job-cleanup.yml
cd ..

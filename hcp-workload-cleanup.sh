#!/usr/bin/env bash
set -e
set -o pipefail

time kube-burner init -c hcp-workload-cleanup.yml

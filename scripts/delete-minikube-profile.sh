#!/usr/bin/env bash
set -euo pipefail

PROFILE="${1:-hermon-dev}"

echo "==> Deleting minikube profile: ${PROFILE}"
minikube delete -p "${PROFILE}"

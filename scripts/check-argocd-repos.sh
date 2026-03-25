#!/usr/bin/env bash
set -euo pipefail

kubectl -n argocd get secrets \
  -l 'argocd.argoproj.io/secret-type in (repository,repo-creds)' \
  -o name

echo
kubectl -n argocd get applications

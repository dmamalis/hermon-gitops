#!/usr/bin/env bash
set -euo pipefail

KEY_PATH="${1:-}"
URL_PREFIX="${2:-git@github.com:dmamalis}"

if [[ -z "${KEY_PATH}" ]]; then
  echo "Usage: $0 <path-to-private-ssh-key> [github-url-prefix]"
  echo "Example: $0 ~/.ssh/hermon_minikube_argocd"
  echo
  echo "Important:"
  echo "- use an SSH key WITHOUT a passphrase"
  echo "- the key must have read access to BOTH hermon-ingest and hermon-gitops"
  exit 1
fi

KEY_PATH="${KEY_PATH/#\~/$HOME}"

if [[ ! -f "${KEY_PATH}" ]]; then
  echo "SSH private key not found: ${KEY_PATH}"
  exit 1
fi

if grep -q "ENCRYPTED" "${KEY_PATH}"; then
  echo "Refusing to use passphrase-protected key: ${KEY_PATH}"
  echo "Create a dedicated unencrypted key for Argo CD bootstrap."
  exit 1
fi

echo "==> Applying Argo CD repo-creds for prefix: ${URL_PREFIX}"

kubectl -n argocd apply -f - <<YAML
apiVersion: v1
kind: Secret
metadata:
  name: github-dmamalis-repo-creds
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: repo-creds
type: Opaque
stringData:
  url: ${URL_PREFIX}
  type: git
  sshPrivateKey: |
$(sed 's/^/    /' "${KEY_PATH}")
YAML

echo "==> Current Argo repo credential secrets"
kubectl -n argocd get secrets \
  -l 'argocd.argoproj.io/secret-type in (repository,repo-creds)' \
  -o name

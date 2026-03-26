#!/usr/bin/env bash
set -euo pipefail

PROFILE="${PROFILE:-hermon-dev}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ENV_FILE:-$REPO_ROOT/hermon/local/dev-secrets.env}"
KUBECONFIG_EXPORT="${KUBECONFIG_EXPORT:-$HOME/.kube/${PROFILE}.yaml}"
REMOVE_LOCAL_SECRETS="${REMOVE_LOCAL_SECRETS:-0}"

SUDO=""
if ! docker ps >/dev/null 2>&1; then
  SUDO="sudo"
fi

echo "==> Wiping profile: $PROFILE"
echo "==> Using sudo prefix: ${SUDO:-<none>}"

echo "==> Stop and delete minikube profile"
$SUDO minikube -p "$PROFILE" stop || true
$SUDO minikube -p "$PROFILE" delete --purge || true

echo "==> Remove leftover docker container if present"
$SUDO docker rm -f "$PROFILE" 2>/dev/null || true

echo "==> Remove kubeconfig entries"
kubectl config delete-context "$PROFILE" 2>/dev/null || true
kubectl config delete-cluster "$PROFILE" 2>/dev/null || true
kubectl config delete-user "$PROFILE" 2>/dev/null || true

echo "==> Remove exported standalone kubeconfig"
rm -f "$KUBECONFIG_EXPORT"

if [[ "$REMOVE_LOCAL_SECRETS" == "1" ]]; then
  echo "==> Removing local dev secret file"
  rm -f "$ENV_FILE"
else
  echo "==> Preserving local dev secret file"
fi

echo "==> Wipe complete"

#!/usr/bin/env bash
set -euo pipefail

PROFILE="${PROFILE:-hermon-dev}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOCAL_ENV_FILE="${LOCAL_ENV_FILE:-$REPO_ROOT/hermon/examples/dev-secrets.env}"
STANDALONE_KUBECONFIG="${STANDALONE_KUBECONFIG:-$HOME/.kube/${PROFILE}.yaml}"
CLEAR_K9S_CACHE="${CLEAR_K9S_CACHE:-1}"

SUDO=""
if ! docker ps >/dev/null 2>&1; then
  SUDO="sudo"
fi

echo "==> Profile: $PROFILE"
echo "==> Repo root: $REPO_ROOT"
echo "==> Local env file: $LOCAL_ENV_FILE"
echo "==> Standalone kubeconfig: $STANDALONE_KUBECONFIG"
echo "==> Clear k9s cache: $CLEAR_K9S_CACHE"
echo "==> Using sudo prefix: ${SUDO:-<none>}"

echo "==> Current minikube profiles before wipe"
$SUDO minikube profile list || true

echo "==> Current kube contexts before wipe"
kubectl config get-contexts || true

echo "==> Stopping and deleting minikube profile"
$SUDO minikube -p "$PROFILE" stop || true
$SUDO minikube -p "$PROFILE" delete --purge || true

echo "==> Removing leftover docker container if present"
$SUDO docker rm -f "$PROFILE" 2>/dev/null || true

echo "==> Removing kubeconfig entries"
kubectl config delete-context "$PROFILE" 2>/dev/null || true
kubectl config delete-cluster "$PROFILE" 2>/dev/null || true
kubectl config delete-user "$PROFILE" 2>/dev/null || true

echo "==> Removing local untracked dev secrets file"
rm -f "$LOCAL_ENV_FILE"

echo "==> Removing standalone kubeconfig export"
rm -f "$STANDALONE_KUBECONFIG"

if [[ "$CLEAR_K9S_CACHE" == "1" ]]; then
  echo "==> Removing k9s cache/state entries for profile if present"
  for base in \
    "$HOME/.local/share/k9s/clusters" \
    "$HOME/.local/state/k9s/clusters"
  do
    [[ -d "$base" ]] || continue
    find "$base" -depth -type d -name "$PROFILE" -print 2>/dev/null | while read -r path; do
      rm -rf "$path"
    done
  done
fi

echo "==> Remaining minikube profiles after wipe"
$SUDO minikube profile list || true

echo "==> Remaining kube contexts after wipe"
kubectl config get-contexts || true

echo "==> Remaining hermon-dev docker objects"
$SUDO docker ps -a --filter "name=$PROFILE" || true

echo "==> Wipe complete"

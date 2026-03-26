#!/usr/bin/env bash
set -euo pipefail

PROFILE="${PROFILE:-hermon-dev}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ENV_FILE:-$REPO_ROOT/hermon/examples/dev-secrets.env}"
KUBECONFIG_EXPORT="${KUBECONFIG_EXPORT:-$HOME/.kube/${PROFILE}.yaml}"

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

echo "==> Remove local dev secrets file"
rm -f "$ENV_FILE"

echo "==> Remove exported standalone kubeconfig"
rm -f "$KUBECONFIG_EXPORT"

echo "==> Remove k9s cached entries for this cluster if present"
for base in \
  "$HOME/.local/share/k9s" \
  "$HOME/.local/state/k9s" \
  "$HOME/.config/k9s"
do
  [[ -d "$base" ]] || continue
  find "$base" -depth \( -type d -o -type f \) -name "$PROFILE" -print 2>/dev/null | while read -r path; do
    rm -rf "$path"
  done
done

echo "==> Remaining minikube profiles"
$SUDO minikube profile list || true

echo "==> Remaining kube contexts"
kubectl config get-contexts || true

echo "==> Remaining docker objects matching profile"
$SUDO docker ps -a --filter "name=$PROFILE" || true

echo "==> Wipe complete"

#!/usr/bin/env bash
set -euo pipefail

PROFILE="${PROFILE:-hermon-dev}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SSH_KEY="${1:-$HOME/.ssh/hermon_minikube_argocd}"
ENV_FILE="${2:-$REPO_ROOT/hermon/examples/dev-secrets.env}"
KUBECONFIG_EXPORT="${3:-$HOME/.kube/${PROFILE}.yaml}"

cd "$REPO_ROOT"

if [[ ! -f "$SSH_KEY" || ! -f "${SSH_KEY}.pub" ]]; then
  echo "ERROR: SSH key not found:" >&2
  echo "  $SSH_KEY" >&2
  echo "  ${SSH_KEY}.pub" >&2
  exit 1
fi

echo "==> Bootstrap minikube + Argo CD"
scripts/bootstrap-minikube-argo.sh

echo "==> Install Argo repo credentials"
./scripts/bootstrap-argocd-github-creds.sh "$SSH_KEY"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "==> Creating fresh local env file from example"
  cp hermon/examples/dev-secrets.env.example "$ENV_FILE"
fi

echo "==> Edit local env file now"
"${EDITOR:-nano}" "$ENV_FILE"

echo "==> Create runtime secrets"
./scripts/bootstrap-hermon-dev-secrets.sh "$ENV_FILE"

echo "==> Verify secrets"
kubectl --context "$PROFILE" -n "$PROFILE" get secrets

echo "==> Apply Hermon app"
kubectl --context "$PROFILE" apply -f apps/hermon-dev.yaml

echo "==> Force Argo refresh"
kubectl --request-timeout=10s --context "$PROFILE" -n argocd annotate application hermon-dev \
  argocd.argoproj.io/refresh=hard --overwrite || true

echo "==> Export standalone kubeconfig"
mkdir -p "$(dirname "$KUBECONFIG_EXPORT")"
kubectl --context "$PROFILE" config view --raw --minify --flatten > "$KUBECONFIG_EXPORT"
chmod 600 "$KUBECONFIG_EXPORT"

echo
echo "==> Current Argo app status"
kubectl --context "$PROFILE" -n argocd get application hermon-dev || true

echo
echo "==> Current workload status"
kubectl --context "$PROFILE" -n "$PROFILE" get jobs,statefulsets,deployments,services,pods || true

echo
echo "==> Standalone kubeconfig written to:"
echo "  $KUBECONFIG_EXPORT"
echo
echo "Use with:"
echo "  KUBECONFIG=$KUBECONFIG_EXPORT k9s"
echo "  kubectl --kubeconfig $KUBECONFIG_EXPORT get pods -A"

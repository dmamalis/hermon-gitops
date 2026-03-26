#!/usr/bin/env bash
set -euo pipefail

PROFILE="${PROFILE:-hermon-dev}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SSH_KEY="${1:-$HOME/.ssh/hermon_minikube_argocd}"
ENV_FILE="${2:-$REPO_ROOT/hermon/local/dev-secrets.env}"
KUBECONFIG_EXPORT="${3:-$HOME/.kube/${PROFILE}.yaml}"
EDIT_SECRETS="${EDIT_SECRETS:-0}"

cd "$REPO_ROOT"

if [[ ! -f "$SSH_KEY" || ! -f "${SSH_KEY}.pub" ]]; then
  echo "ERROR: SSH key not found:" >&2
  echo "  $SSH_KEY" >&2
  echo "  ${SSH_KEY}.pub" >&2
  exit 1
fi

mkdir -p "$(dirname "$ENV_FILE")"
chmod 700 "$(dirname "$ENV_FILE")"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "==> No local dev secret file found"
  echo "==> Creating $ENV_FILE from template"
  cp hermon/examples/dev-secrets.env.example "$ENV_FILE"
  chmod 600 "$ENV_FILE"
  echo "==> Fill in the local secret file once"
  "${EDITOR:-nano}" "$ENV_FILE"
elif [[ "$EDIT_SECRETS" == "1" ]]; then
  echo "==> Editing existing local secret file: $ENV_FILE"
  "${EDITOR:-nano}" "$ENV_FILE"
else
  chmod 600 "$ENV_FILE"
  echo "==> Using existing local secret file: $ENV_FILE"
fi

echo "==> Bootstrap minikube + Argo CD"
scripts/bootstrap-minikube-argo.sh

echo "==> Install Argo repo credentials"
./scripts/bootstrap-argocd-github-creds.sh "$SSH_KEY"

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

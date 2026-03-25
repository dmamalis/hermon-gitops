#!/usr/bin/env bash
set -euo pipefail

PROFILE="${1:-hermon-dev}"

echo "==> Starting minikube profile: ${PROFILE}"
minikube start -p "${PROFILE}"

echo "==> Switching kubectl context"
kubectl config use-context "${PROFILE}"

echo "==> Creating argocd namespace if needed"
kubectl get namespace argocd >/dev/null 2>&1 || kubectl create namespace argocd

echo "==> Installing/updating Argo CD"
kubectl apply -n argocd --server-side --force-conflicts \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "==> Waiting for Argo CD core deployments"
kubectl -n argocd rollout status deploy/argocd-server --timeout=300s
kubectl -n argocd rollout status deploy/argocd-repo-server --timeout=300s

echo "==> Current pods"
kubectl -n argocd get pods

echo
echo "Done."
echo "Access Argo with:"
echo "  kubectl -n argocd port-forward svc/argocd-server 8080:443"
echo
echo "Get initial admin password with:"
echo "  kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d && echo"

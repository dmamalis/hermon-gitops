#!/usr/bin/env bash
set -euo pipefail

PROFILE="${1:-hermon-dev}"
OUT="${2:-$HOME/.kube/${PROFILE}.yaml}"

mkdir -p "$(dirname "$OUT")"

kubectl --context "$PROFILE" config view --raw --minify --flatten > "$OUT"
chmod 600 "$OUT"

echo "Wrote standalone kubeconfig:"
echo "  $OUT"
echo
echo "Use with:"
echo "  KUBECONFIG=$OUT k9s"

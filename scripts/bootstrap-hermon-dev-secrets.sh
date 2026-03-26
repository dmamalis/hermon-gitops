#!/usr/bin/env bash
set -euo pipefail

ENV_FILE="${1:-hermon/examples/dev-secrets.env}"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "ERROR: env file not found: $ENV_FILE" >&2
  echo "Example:" >&2
  echo "  cp hermon/examples/dev-secrets.env.example hermon/examples/dev-secrets.env" >&2
  echo "  \$EDITOR hermon/examples/dev-secrets.env" >&2
  exit 1
fi

set -a
# shellcheck disable=SC1090
source "$ENV_FILE"
set +a

NAMESPACE="${NAMESPACE:-hermon-dev}"

require_vars() {
  local missing=()
  local v
  for v in "$@"; do
    if [[ -z "${!v:-}" ]]; then
      missing+=("$v")
    fi
  done
  if (( ${#missing[@]} > 0 )); then
    echo "ERROR: missing required vars: ${missing[*]}" >&2
    exit 1
  fi
}

require_not_placeholder() {
  local bad=()
  local v
  for v in "$@"; do
    case "${!v:-}" in
      ""|"change-me"|"you@example.com")
        bad+=("$v")
        ;;
    esac
  done
  if (( ${#bad[@]} > 0 )); then
    echo "ERROR: placeholder values still present for: ${bad[*]}" >&2
    exit 1
  fi
}

maybe_create_ttn_secret() {
  if [[ -n "${TTN_USERNAME:-}" && -n "${TTN_PASSWORD:-}" && "${TTN_USERNAME}" != "change-me" && "${TTN_PASSWORD}" != "change-me" ]]; then
    kubectl -n "$NAMESPACE" create secret generic telegraf-ttn-secret \
      --from-literal=TTN_USERNAME="$TTN_USERNAME" \
      --from-literal=TTN_PASSWORD="$TTN_PASSWORD" \
      --dry-run=client -o yaml | kubectl apply -f -
    echo "Created/updated secret: telegraf-ttn-secret"
  else
    echo "Skipping telegraf-ttn-secret (TTN_USERNAME / TTN_PASSWORD not fully set)"
  fi
}

maybe_create_ghcr_secret() {
  local server="${GHCR_SERVER:-ghcr.io}"
  local email="${GHCR_EMAIL:-none@example.com}"

  if [[ -n "${GHCR_USERNAME:-}" && -n "${GHCR_PASSWORD:-}" && "${GHCR_USERNAME}" != "change-me" && "${GHCR_PASSWORD}" != "change-me" ]]; then
    kubectl -n "$NAMESPACE" create secret docker-registry ghcr-pull-secret \
      --docker-server="$server" \
      --docker-username="$GHCR_USERNAME" \
      --docker-password="$GHCR_PASSWORD" \
      --docker-email="$email" \
      --dry-run=client -o yaml | kubectl apply -f -
    echo "Created/updated secret: ghcr-pull-secret"
  else
    echo "Skipping ghcr-pull-secret (GHCR_USERNAME / GHCR_PASSWORD not fully set)"
  fi
}

require_vars \
  POSTGRES_USER \
  POSTGRES_PASSWORD \
  TELEMETRY_DB_NAME \
  TELEMETRY_WRITER_USER \
  TELEMETRY_WRITER_PASSWORD \
  TELEMETRY_READER_USER \
  TELEMETRY_READER_PASSWORD \
  GF_DATABASE_NAME \
  GF_DATABASE_USER \
  GF_DATABASE_PASSWORD

require_not_placeholder \
  POSTGRES_USER \
  POSTGRES_PASSWORD \
  TELEMETRY_DB_NAME \
  TELEMETRY_WRITER_USER \
  TELEMETRY_WRITER_PASSWORD \
  TELEMETRY_READER_USER \
  TELEMETRY_READER_PASSWORD \
  GF_DATABASE_NAME \
  GF_DATABASE_USER \
  GF_DATABASE_PASSWORD

kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

kubectl -n "$NAMESPACE" create secret generic timescaledb-auth \
  --from-literal=POSTGRES_USER="$POSTGRES_USER" \
  --from-literal=POSTGRES_PASSWORD="$POSTGRES_PASSWORD" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "Created/updated secret: timescaledb-auth"

kubectl -n "$NAMESPACE" create secret generic telemetry-db-secret \
  --from-literal=TELEMETRY_DB_NAME="$TELEMETRY_DB_NAME" \
  --from-literal=TELEMETRY_WRITER_USER="$TELEMETRY_WRITER_USER" \
  --from-literal=TELEMETRY_WRITER_PASSWORD="$TELEMETRY_WRITER_PASSWORD" \
  --from-literal=TELEMETRY_READER_USER="$TELEMETRY_READER_USER" \
  --from-literal=TELEMETRY_READER_PASSWORD="$TELEMETRY_READER_PASSWORD" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "Created/updated secret: telemetry-db-secret"

kubectl -n "$NAMESPACE" create secret generic grafana-secret \
  --from-literal=GF_DATABASE_NAME="$GF_DATABASE_NAME" \
  --from-literal=GF_DATABASE_USER="$GF_DATABASE_USER" \
  --from-literal=GF_DATABASE_PASSWORD="$GF_DATABASE_PASSWORD" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "Created/updated secret: grafana-secret"

maybe_create_ttn_secret
maybe_create_ghcr_secret

echo
echo "Done."
echo
echo "Verify with:"
echo "  kubectl -n $NAMESPACE get secrets"

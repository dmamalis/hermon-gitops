# Hermon secret handling

## Purpose

This document explains which runtime secrets Hermon expects, where they are referenced, and how to populate a fresh dev cluster safely.

Real secret values must never be committed to Git.

## Current model

Hermon runtime manifests reference pre-created Kubernetes Secrets by name.
The GitOps repo owns the references to those secret names, but not the secret values themselves.

## Required secrets for `hermon-dev`

### 1. `timescaledb-auth`

Used by:
- TimescaleDB
- `db-bootstrap` job

Expected keys:
- `POSTGRES_USER`
- `POSTGRES_PASSWORD`

### 2. `telemetry-db-secret`

Used by:
- Telegraf output to TimescaleDB
- `db-bootstrap` job

Expected keys:
- `TELEMETRY_DB_NAME`
- `TELEMETRY_WRITER_USER`
- `TELEMETRY_WRITER_PASSWORD`
- `TELEMETRY_READER_USER`
- `TELEMETRY_READER_PASSWORD`

### 3. `grafana-secret`

Used by:
- Grafana DB configuration
- `db-bootstrap` job

Expected keys:
- `GF_DATABASE_NAME`
- `GF_DATABASE_USER`
- `GF_DATABASE_PASSWORD`

### 4. `telegraf-ttn-secret`

Used by:
- Telegraf TTN / MQTT configuration

Expected keys:
- define the exact keys used by the deployed Telegraf config
- keep this aligned with the chart and the Telegraf config files

### 5. `ghcr-pull-secret`

Used by:
- image pulls for private GHCR images if required

## Important behavior

A fresh `hermon-dev` cluster will not become healthy unless these runtime secrets exist.
In particular, the `db-bootstrap` sync hook cannot start if `timescaledb-auth`, `telemetry-db-secret`, or `grafana-secret` are missing.

## Safe-to-commit files

Safe to commit:
- `.env.example` files with placeholder values
- scripts that create secrets from local env files
- documentation about secret names and required keys

Never commit:
- real `.env` files with secrets
- exported Kubernetes Secret manifests containing real values
- copied secrets from another cluster

## Recommended dev workflow

1. Copy the example template locally:
   - `cp hermon/examples/dev-secrets.env.example hermon/examples/dev-secrets.env`

2. Fill in real local values in the untracked file.

3. Create or update the secrets in the target namespace:
   - `./scripts/bootstrap-hermon-dev-secrets.sh hermon/examples/dev-secrets.env`

4. Apply or refresh the Argo CD application.

## Temporary migration workaround

If a new dev cluster already exists and is missing secrets, it is acceptable to export the required Secrets from an existing working dev cluster and apply them to the new one.

This is only a temporary operational shortcut.
Those exported files must remain local and be deleted after use.

## Future direction

Production-grade secret handling should later move to one of:
- SOPS / age
- Sealed Secrets
- External Secrets
- Vault or equivalent

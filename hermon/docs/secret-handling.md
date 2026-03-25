# Hermon secret handling

## Purpose

This document records the current secret model for the Hermon k3s / Argo CD deployment.

It is intentionally practical and reflects the current working setup.

## Current model

Current status:

- secret values are not committed to Git
- Kubernetes manifests reference secret names and keys only
- safe example env files live in `hermon-ingest`
- real local env files are ignored from Git
- cluster secrets are currently created manually

This matches the current pre-Helm cleanup goal of documenting the secret model without redesigning it.

---

## Secret ownership boundary

### `hermon-ingest`
Owns:
- safe `*.env.example` files
- app-facing variable names
- config files that consume environment variables

Does not own:
- Kubernetes Secret manifests with real values
- cluster secret creation steps

### `hermon-gitops`
Owns:
- Kubernetes secret references in manifests
- documentation of which secrets must exist in cluster
- documentation of which workloads consume which secret keys

Does not own:
- committed secret values

---

## Secrets currently required in cluster

### 1. `telegraf-db-secret`

Used by:
- `hermon/base/telegraf/deployment.yaml`

Required keys:
- `TS_PG_CONN`

Purpose:
- PostgreSQL connection string used by Telegraf output

Consumed as:
- environment variable `TS_PG_CONN`

---

### 2. `telegraf-ttn-secret`

Used by:
- `hermon/base/telegraf/deployment.yaml`

Required keys:
- `TTN_USERNAME`
- `TTN_PASSWORD`

Purpose:
- TTN MQTT credentials for optional TTN Telegraf input

Consumed as:
- environment variable `TTN_USERNAME`
- environment variable `TTN_PASSWORD`

---

### 3. `grafana-secret`

Used by:
- `hermon/base/grafana/deployment.yaml`

Required keys:
- `GF_SECURITY_ADMIN_USER`
- `GF_SECURITY_ADMIN_PASSWORD`
- `GF_DATABASE_NAME`
- `GF_DATABASE_USER`
- `GF_DATABASE_PASSWORD`
- `GRAFANA_DB_USER`
- `GRAFANA_DB_PASSWORD`
- `GRAFANA_DB_NAME`

Purpose:
- Grafana admin login
- Grafana internal database connection settings
- Grafana datasource provisioning variables for the Hermon Timescale datasource file

Consumed as:
- Grafana runtime env vars (`GF_*`)
- datasource provisioning env vars (`GRAFANA_DB_*`)

Note:
- today there is some intentional duplication in the secret because Grafana itself uses `GF_DATABASE_*`, while the provisioned datasource file uses `GRAFANA_DB_*`

---

### 4. `timescaledb-auth`

Used by:
- `hermon/base/timescaledb/statefulset.yaml`

Required keys:
- `POSTGRES_USER`
- `POSTGRES_PASSWORD`
- `POSTGRES_DB`

Purpose:
- initialize and run the TimescaleDB/Postgres container

Consumed as:
- environment variable `POSTGRES_USER`
- environment variable `POSTGRES_PASSWORD`
- environment variable `POSTGRES_DB`

---

### 5. `ghcr-pull-secret`

Used by:
- `hermon/base/hermon-ingest/deployment.yaml`

Purpose:
- image pull secret for the private or authenticated GHCR image pull path

Consumed as:
- `imagePullSecrets`

Note:
- this is different from app runtime secrets
- it is still a required manually managed cluster secret

---

## Manifest reference summary

### Telegraf
Manifest:
- `hermon/base/telegraf/deployment.yaml`

Secret refs:
- `telegraf-db-secret` -> `TS_PG_CONN`
- `telegraf-ttn-secret` -> `TTN_USERNAME`
- `telegraf-ttn-secret` -> `TTN_PASSWORD`

### Grafana
Manifest:
- `hermon/base/grafana/deployment.yaml`

Secret refs:
- `grafana-secret` -> `GF_SECURITY_ADMIN_USER`
- `grafana-secret` -> `GF_SECURITY_ADMIN_PASSWORD`
- `grafana-secret` -> `GF_DATABASE_NAME`
- `grafana-secret` -> `GF_DATABASE_USER`
- `grafana-secret` -> `GF_DATABASE_PASSWORD`
- `grafana-secret` -> `GRAFANA_DB_USER`
- `grafana-secret` -> `GRAFANA_DB_PASSWORD`
- `grafana-secret` -> `GRAFANA_DB_NAME`

### TimescaleDB
Manifest:
- `hermon/base/timescaledb/statefulset.yaml`

Secret refs:
- `timescaledb-auth` -> `POSTGRES_USER`
- `timescaledb-auth` -> `POSTGRES_PASSWORD`
- `timescaledb-auth` -> `POSTGRES_DB`

### Hermon ingest image pull
Manifest:
- `hermon/base/hermon-ingest/deployment.yaml`

Secret refs:
- `ghcr-pull-secret` as `imagePullSecrets`

---

## Safe example env files

Canonical safe example env files live in `hermon-ingest`:

- `compose/env/decoder.env.example`
- `compose/env/grafana.env.example`
- `compose/env/telegraf.env.example`
- `compose/env/timescale.env.example`

These are safe to commit because they are examples only and use placeholder values.

---

## Local files that must never be committed

In `hermon-ingest`, real local env files under:

- `compose/env/*.env`

must never be committed.

This is enforced by `.gitignore`, which ignores:

- `compose/env/*.env`

while keeping:

- `compose/env/*.env.example`

tracked.

Also, real values must not be added to GitOps manifests or docs.

---

## Current operational rule

When adding or changing secret-backed configuration:

1. define the variable shape in the canonical app-layer config if needed
2. keep safe example values only in `hermon-ingest`
3. reference the secret from `hermon-gitops` manifests
4. create or update the real secret manually in cluster
5. never commit real secret material to either repo

---

## Future production direction

This repo does not yet implement a production-grade secret manager workflow.

Later options may include:

- SOPS / age
- Sealed Secrets
- External Secrets
- Vault or equivalent

That is a future production path, not part of the current cleanup step.

---

## Current assessment

The current secret model is acceptable for the pre-Helm cleanup stage because:

- secret values are out of Git
- references are explicit in manifests
- local examples are separated from real values
- the working runtime behavior is preserved

The main goal of this phase is clarity and consistency, not redesign.

# Hermon DB Config Audit

## Scope
This audit is limited to:
- Timescale/Postgres bootstrap/admin credentials
- telemetry database connection
- Grafana internal database connection
- Grafana datasource connection
- secret and env ownership

## Current findings

### Telegraf write path
- Telegraf does not hardcode the target DB in `telegraf.conf`
- it uses `TS_PG_CONN`
- this means telemetry DB name/user changes are primarily secret/env changes

### Grafana internal DB
- Grafana internal DB is configured through `GF_DATABASE_*`
- chart templates already expect these values from `grafana-secret`

### Grafana datasource DB
- Grafana datasource provisioning uses `GRAFANA_DB_*`
- datasource file already resolves DB name/user/password from env vars

### Current drift
- local env examples still reference legacy names such as `tsdb`, `telegraf`, and `postgres`
- root README still includes legacy DB examples
- fresh environments currently do not bootstrap the full DB/role model declaratively

## Target model

### Bootstrap/admin
- secret: `timescaledb-auth`
- role: `postgres`
- purpose: bootstrap/admin only

### Telemetry database
- database: `hermon`
- writer role: `telemetry_writer`
- reader role: `telemetry_reader`

### Grafana internal database
- database: `grafana`
- app role: `grafana_app`

## Target secret model

### `timescaledb-auth`
- `POSTGRES_USER`
- `POSTGRES_PASSWORD`
- `POSTGRES_DB`

Recommended intent:
- bootstrap/admin only
- preferred DB value: `postgres`

### `telegraf-db-secret`
Keep the secret name for now, but make it target the telemetry DB through:
- `TS_PG_CONN=host=timescaledb port=5432 user=telemetry_writer password=... dbname=hermon sslmode=disable`

### `grafana-secret`
Grafana internal DB:
- `GF_DATABASE_NAME=grafana`
- `GF_DATABASE_USER=grafana_app`
- `GF_DATABASE_PASSWORD=...`

Grafana datasource DB:
- `GRAFANA_DB_NAME=hermon`
- `GRAFANA_DB_USER=telemetry_reader`
- `GRAFANA_DB_PASSWORD=...`

Also keep:
- `GF_SECURITY_ADMIN_USER`
- `GF_SECURITY_ADMIN_PASSWORD`

### `telegraf-ttn-secret`
- unchanged

## Ownership

### `hermon-ingest`
Owns:
- chart bootstrap Job
- DB bootstrap SQL/script logic
- packaged deploy behavior

### `hermon-gitops`
Owns:
- environment-specific secret values
- secret names
- environment-specific deployment values

## Follow-up changes

1. update env examples and docs to reflect the new DB model
2. add an idempotent chart-managed bootstrap Job for DBs/roles/grants
3. test fresh deployment in Minikube
4. migrate k3s secrets/values to the same model

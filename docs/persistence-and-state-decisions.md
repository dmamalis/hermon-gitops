# Hermon persistence and state decisions

## Purpose

This document records the current persistence model of the Hermon stack and the intended expectations before later Helm packaging.

It is a planning and clarification document.
It does not redesign the current architecture.

## Why this exists

Before production-oriented packaging, the stateful parts of the stack should be deliberate, not accidental.

This document answers:

- what data is persistent today
- what data is disposable today
- what recovery is expected after pod restart, rescheduling, or cluster loss
- what should remain true when Helm packaging starts later

---

## Current stack view

Current components:

- TimescaleDB
- hermon-ingest
- Telegraf
- Grafana

State posture today:

- TimescaleDB is the primary persistent stateful component
- hermon-ingest is stateless
- Telegraf is stateless
- Grafana is currently treated as disposable and provisioned from files

---

## Component-by-component decisions

### 1. TimescaleDB

Current state:
- deployed as a `StatefulSet`
- uses a PVC via `volumeClaimTemplates`
- requests `20Gi` storage
- stores the application time-series data

Decision:
- TimescaleDB is persistent by design
- data loss here is real application data loss
- this component must remain stateful in future packaging

Operational expectation:
- pod restart should not lose database contents
- rescheduling on the same cluster should preserve data through the PVC
- cluster loss without storage backup should be treated as data loss

Backup expectation:
- backup strategy is required before calling the stack production-ready
- backup mechanism does not need to be implemented in this phase
- but the expectation must be explicit: TimescaleDB data is important and must be recoverable

Future Helm posture:
- persistence enabled by default
- storage size should later become a Helm value
- storage class may later become an optional Helm value

---

### 2. hermon-ingest

Current state:
- deployed as a `Deployment`
- no persistent volume
- consumes config via ConfigMap
- processes requests and forwards data onward

Decision:
- hermon-ingest is stateless by design
- it should remain disposable and easily replaceable

Operational expectation:
- pod restart should be safe
- rescheduling should be safe
- no application data should depend on local container filesystem state

Future Helm posture:
- no persistence required
- keep this component stateless unless a future architecture change clearly requires otherwise

---

### 3. Telegraf

Current state:
- deployed as a `Deployment`
- config provided by ConfigMaps
- no persistent volume
- acts as ingestion/forwarding pipeline component

Decision:
- Telegraf is stateless by design in the current stack
- it should remain disposable for this deployment model

Operational expectation:
- pod restart should be safe
- rescheduling should be safe
- config is externalized, so local filesystem state is not important

Important note:
- transient in-flight ingestion during restart may be lost
- that is acceptable in the current model unless future requirements say otherwise

Future Helm posture:
- no persistence required
- keep stateless unless queueing or buffering requirements change later

---

### 4. Grafana

Current state:
- deployed as a `Deployment`
- uses file-based provisioning for datasources and dashboards
- currently mounts `emptyDir` at `/var/lib/grafana`
- no persistent Grafana storage is currently kept
- dashboard definitions are provisioned from files, not authored in-cluster

Decision:
- Grafana is currently treated as disposable
- this is acceptable for the current Hermon deployment model

Operational expectation:
- pod restart may reset local Grafana runtime state stored under `/var/lib/grafana`
- provisioned datasources and dashboards should return automatically because they come from files
- manually created UI state inside Grafana should not be relied upon unless persistence strategy changes later

SQLite decision:
- Grafana can continue using its local default SQLite database for this deployment model for now
- this is acceptable because Grafana is being treated as disposable and provisioned from code-managed assets
- this should not be mistaken for a durable state strategy

Important consequence:
- if users start relying on ad-hoc dashboards, local users, preferences, alert history, or other mutable in-Grafana state, the current disposable model becomes insufficient

Future Helm posture:
- default posture can remain disposable Grafana
- later, persistence may become optional if the operational model changes
- do not add Grafana persistence just for formality if the intended model is still fully provisioned/disposable

---

## Recovery expectations

### Pod restart

Expected result:

- TimescaleDB: data should remain
- hermon-ingest: safe to restart
- Telegraf: safe to restart
- Grafana: should come back with provisioned dashboards/datasources, but local mutable Grafana state is not guaranteed

### Pod rescheduling within the cluster

Expected result:

- TimescaleDB: should retain data as long as the persistent volume remains available and reattached correctly
- hermon-ingest: safe
- Telegraf: safe
- Grafana: safe under disposable model, but local runtime state remains non-durable

### Full cluster loss

Expected result:

- TimescaleDB: data is lost unless external backup or durable storage recovery exists
- hermon-ingest: redeployable
- Telegraf: redeployable
- Grafana: redeployable from provisioning assets, but any mutable Grafana-local state is lost

Operational meaning:
- the main disaster-recovery concern is TimescaleDB
- Grafana is recoverable as configuration, not as durable mutable state, under the current model

---

## Current decision summary

### Persistent by design
- TimescaleDB

### Disposable by design
- hermon-ingest
- Telegraf
- Grafana

### Durable data that matters
- TimescaleDB contents

### Durable configuration that matters
- canonical Telegraf config in `hermon-ingest`
- canonical Grafana provisioning/dashboard assets in `hermon-ingest`
- Kubernetes deployment wiring in `hermon-gitops`

### Non-durable runtime state currently accepted
- Grafana local SQLite/runtime state
- any non-persisted transient state in stateless services

---

## What this means before Helm

When Helm work starts later:

- TimescaleDB should be charted as persistent
- hermon-ingest should be charted as stateless
- Telegraf should be charted as stateless
- Grafana may remain charted as disposable by default
- persistence should not be added to components unless the operational model actually needs it

---

## Open production questions for later

These do not block current cleanup, but should be reviewed before calling the stack production-ready:

- what backup mechanism will protect TimescaleDB data
- what recovery point/recovery time expectations exist for database loss
- whether Grafana should remain fully disposable in production
- whether any future alerting/history/user-management features create a need for Grafana persistence
- whether PVC/storage class choices need environment-specific variation

---

## Current recommendation

Keep the current model:

- TimescaleDB persistent
- all other services disposable
- Grafana provisioned from files and acceptable with local SQLite for now

This is consistent with the current working architecture and avoids unnecessary redesign before Helm.

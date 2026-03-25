# Hermon upgrade and rollout strategy

## Purpose

This document defines how updates should be expected to roll in the current Hermon deployment model before later Helm packaging.

It is a planning and operational clarity document.
It does not change the deployment by itself.

## Why this exists

Before production packaging, it should be clear:

- which updates are safe and routine
- which updates are potentially disruptive
- which updates are reversible
- which updates need special care

This avoids treating every change as if it had the same operational risk.

---

## Current component update model

Current components:

- `hermon-ingest`
- `telegraf`
- `grafana`
- `timescaledb`

Operational posture today:

- `hermon-ingest`, `telegraf`, and `grafana` are single-replica workloads
- `timescaledb` is a single-replica stateful workload
- changes are currently applied through GitOps reconciliation

This means many changes are effectively rolling replacements, but not all of them carry the same risk.

---

## Component-by-component rollout expectations

### 1. `hermon-ingest`

Typical change types:

- new application image tag
- env/config changes through `hermon-ingest-config`
- probe changes
- service or ingress adjustments

Expected rollout behavior:
- normally safe and routine
- pod replacement is expected
- brief interruption during restart is acceptable in the current model

Reversibility:
- usually reversible by restoring the previous image tag or manifest

Risk level:
- low to medium

Notes:
- first-party image updates should follow the documented image versioning policy
- avoid reusing tags for different content
- rollback should mean moving back to a previously known-good immutable image

---

### 2. Telegraf

Typical change types:

- base config change
- optional input fragment change
- secret reference change
- image change

Expected rollout behavior:
- config or image changes will restart the Telegraf pod
- brief ingestion interruption is expected during restart
- transient in-flight data may be lost during restart in the current model

Reversibility:
- usually reversible by restoring the previous config or image

Risk level:
- medium

Notes:
- Telegraf config is app-owned canonically in `hermon-ingest`
- deployed copies in `hermon-gitops` should only change after canonical files are updated
- config changes should be treated as operational changes, not only formatting changes

Important expectation:
- a Telegraf config change is not risk-free just because it is file-based
- malformed config can break ingestion until corrected

---

### 3. Grafana

Typical change types:

- dashboard JSON updates
- datasource provisioning updates
- provider provisioning updates
- image change
- secret/env changes

Expected rollout behavior:
- provisioning changes may require pod restart or pod recreation depending on how ConfigMap updates are applied and observed
- current deployment model should assume restart/recreate is the safe convergence mechanism
- Grafana is treated as disposable in the current architecture

Reversibility:
- usually reversible by restoring previous provisioning assets or image

Risk level:
- low to medium

Notes:
- because Grafana is provisioned from files and treated as disposable, rollout risk is mostly around UI availability and provisioning correctness, not durable state loss
- malformed provisioning can break dashboard or datasource availability until corrected

---

### 4. TimescaleDB

Typical change types:

- image version change
- storage-related changes
- auth secret changes
- StatefulSet manifest changes

Expected rollout behavior:
- this is the highest-risk update area in the stack
- database upgrades must not be treated like routine stateless rollouts
- storage and version changes may require planned procedures, not simple GitOps confidence

Reversibility:
- not always safely reversible
- database version upgrades can be non-trivial or non-reversible without backups or explicit downgrade strategy

Risk level:
- high

Notes:
- TimescaleDB changes should be treated separately from app-layer rollouts
- backup expectations matter here
- never assume a database image bump is equivalent to a stateless image bump

Important expectation:
- production packaging should treat TimescaleDB upgrades as controlled operations, not casual background updates

---

## Reversible vs non-reversible change categories

### Usually reversible
- `hermon-ingest` image tag rollback
- Telegraf config rollback
- Grafana dashboard/provisioning rollback
- ingress/service adjustments
- most stateless manifest changes

### Potentially non-reversible or operationally sensitive
- TimescaleDB version upgrades
- storage class or PVC-related changes
- schema/data migrations if introduced later
- secret rotations that invalidate existing connectivity unless coordinated
- destructive manifest changes affecting persistent storage

---

## Practical rollout guidance

### Safe routine changes
These are generally acceptable through normal GitOps flow:

- `hermon-ingest` image updates
- Telegraf config updates after validation
- Grafana dashboard and provisioning updates
- non-destructive ingress/service adjustments

### Changes needing extra caution
These should be treated more carefully:

- secret rotations
- probe changes that may destabilize rollout
- changes to externally visible ingest behavior
- Grafana datasource changes that can break dashboards

### Changes needing explicit operational procedure
These should not be treated as routine GitOps edits:

- TimescaleDB image upgrades across meaningful versions
- storage/PVC changes
- any future database migration steps

---

## Current GitOps expectation

Current assumption:

- Argo CD reconciles the desired state
- workload restart or recreation is an acceptable way for config changes to converge
- stateless components may experience short interruptions during rollout
- stateful database changes require extra operational judgment

This is acceptable for the current pre-Helm stage.

---

## Validation expectation after changes

After routine updates, validate at least:

### After `hermon-ingest` updates
- ingress still responds
- ingest endpoint still accepts payloads
- downstream flow continues

### After Telegraf updates
- pod becomes healthy
- data continues landing in TimescaleDB
- optional inputs still authenticate if enabled

### After Grafana updates
- pod becomes healthy
- datasource is present
- dashboards load correctly

### After TimescaleDB-related updates
- StatefulSet is healthy
- database accepts connections
- recent data is still present
- dependent services reconnect successfully

---

## Current recommendation

Treat updates in three buckets:

### Routine stateless rollouts
- `hermon-ingest`
- Telegraf
- Grafana

### Cautious config-affecting rollouts
- secret changes
- ingress behavior changes
- datasource/provisioning changes

### Controlled stateful operations
- TimescaleDB upgrades
- storage-related changes

This is the right level of clarity before Helm.
It keeps rollout expectations explicit without introducing premature orchestration complexity.

---

## Future Helm implication

When Helm work begins later:

- stateless image/config rollouts can remain straightforward
- Telegraf and Grafana config should still be traceable back to canonical app assets
- database upgrades should be documented separately from normal chart upgrades
- not every chart upgrade should be assumed equally safe

## Final assessment

Hermon is already in a workable place for GitOps-based updates, but the risk profile differs by component.

The key rule going forward is:

- stateless rollouts are usually routine
- config rollouts need validation
- database upgrades are special operations

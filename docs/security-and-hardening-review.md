# Hermon security and production hardening review

## Purpose

This document records the current security and hardening posture of the Hermon k3s deployment before later Helm packaging.

It is a review document.
It does not change the working deployment by itself.

This phase is about making the current posture explicit and identifying which improvements matter before production packaging.

## Scope reviewed

Reviewed against the current manifests:

- `hermon/base/hermon-ingest/deployment.yaml`
- `hermon/base/hermon-ingest/service.yaml`
- `hermon/base/hermon-ingest/ingress.yaml`
- `hermon/base/telegraf/deployment.yaml`
- `hermon/base/telegraf/service.yaml`
- `hermon/base/grafana/deployment.yaml`
- `hermon/base/grafana/service.yaml`
- `hermon/base/grafana/ingress.yaml`
- `hermon/base/timescaledb/statefulset.yaml`
- `hermon/base/timescaledb/service.yaml`

Review topics came from the pre-Helm cleanup plan:

- `securityContext`
- running as non-root where possible
- minimal service exposure
- ingress restrictions if needed for ingestion
- secret references instead of literal values
- resource requests/limits review
- health probe sanity review

---

## Current assessment summary

Current posture is acceptable for a working pre-Helm test deployment, but not yet strong enough to call production-hardened.

Main strengths today:

- secrets are referenced from Kubernetes Secrets instead of committed as literal manifest values
- service exposure is already relatively limited
- TimescaleDB is internal-only
- Telegraf is internal-only
- health probes exist for all core workloads
- TimescaleDB already has explicit resource requests and a memory limit

Main gaps today:

- no workload currently declares a pod or container `securityContext`
- manifests do not explicitly enforce non-root execution
- `hermon-ingest`, `telegraf`, and `grafana` do not currently declare resource requests/limits
- ingress is currently plain HTTP on the Traefik `web` entrypoint
- ingest is exposed broadly through Ingress with no extra restrictions yet
- ingest and Telegraf probes are only TCP-level checks, not application-aware health checks

---

## Acceptable as-is for the current stage

### 1. Secret references are already handled correctly

Current manifests use `secretKeyRef` and `imagePullSecrets` instead of embedding real secret values in Git.

This is already aligned with the current pre-Helm cleanup goals.

Affected workloads:

- Telegraf
- Grafana
- TimescaleDB
- Hermon ingest image pull secret

Assessment:
- acceptable as-is for this phase

---

### 2. Service exposure is already fairly minimal

Current exposure model:

- `timescaledb` is internal only through a headless Service
- `telegraf` is internal only through a ClusterIP-style Service
- `grafana` is exposed through Ingress
- `hermon-ingest` is exposed through Ingress

Assessment:
- acceptable as a simple current model
- internal services are not unnecessarily exposed externally

---

### 3. Basic health probes already exist

Current probe posture:

- `hermon-ingest`: readiness + liveness via TCP socket
- `telegraf`: readiness + liveness via TCP socket
- `grafana`: startup + readiness + liveness via HTTP health endpoint
- `timescaledb`: readiness + liveness via `pg_isready`

Assessment:
- acceptable baseline coverage exists
- not perfect, but not missing

---

### 4. TimescaleDB already has explicit resource settings

Current posture:

- CPU request: `250m`
- memory request: `512Mi`
- memory limit: `1Gi`

Assessment:
- good baseline for the stateful database component

---

## Should improve before production packaging

### 1. Add explicit `securityContext` review and decisions

Current posture:
- no `securityContext` is declared in the reviewed workload manifests

Why this matters:
- there is currently no explicit runtime posture for user/group, privilege escalation, filesystem mutability, or capabilities
- current behavior depends on container image defaults rather than declared manifest policy

Recommended pre-production direction:
- review each workload for a safe explicit `securityContext`
- avoid applying a single blanket policy without checking image compatibility first

Priority:
- high

---

### 2. Review non-root execution explicitly

Current posture:
- manifests do not declare `runAsNonRoot`, `runAsUser`, or equivalent controls

Important nuance:
- this does **not** prove workloads are running as root
- it means the manifests do not enforce a non-root posture, so actual behavior depends on each image default

Recommended pre-production direction:
- verify image compatibility
- enforce non-root where practical, especially for:
  - `hermon-ingest`
  - `telegraf`
  - `grafana`
- treat `timescaledb` more carefully because stateful images often have stricter filesystem/runtime assumptions

Priority:
- high

---

### 3. Add resource requests and limits for non-database workloads

Current posture:

- `timescaledb`: resources defined
- `hermon-ingest`: no resources defined
- `telegraf`: no resources defined
- `grafana`: no resources defined

Why this matters:
- without requests, scheduling expectations are weaker
- without limits, runaway behavior is less controlled
- pre-production packaging should not leave this undefined for core workloads

Recommended pre-production direction:
- do not guess shared base values yet
- treat resource policy as environment-specific unless there is an immediate operational need
- later define resource defaults through a cluster-specific overlay or Helm values
- introduce them first where measurement or cluster pressure justifies them

Priority:
- medium

---

### 4. Review ingress exposure for ingestion

Current posture:

- `hermon-ingest` is exposed through Traefik Ingress on:
  - host: `ingest.hermon`
  - path: `/`
  - entrypoint: `web`

Why this matters:
- ingest is a write path into the stack
- production packaging may require stricter controls than a plain open HTTP ingress

Recommended pre-production direction:
- review whether ingest needs additional restrictions such as:
  - TLS
  - trusted-network restriction
  - rate limiting
  - auth only if the ingest protocol allows it cleanly

Priority:
- medium to high

---

### 5. Revisit probe quality for `hermon-ingest` and `telegraf`

Current posture:
- both use TCP socket probes only

Why this matters:
- TCP probes only confirm the port is open
- they do not confirm full application readiness or useful downstream health

Recommended pre-production direction:
- keep current probes for now if they are stable
- later prefer application-aware probes where the app contract supports them

Priority:
- medium

---

## Later / optional hardening

These are valid hardening steps, but they do not need to block the current cleanup flow.

### 1. Read-only root filesystem where compatible
Potentially useful for:

- `hermon-ingest`
- `telegraf`
- `grafana`

Only after verifying container write paths and runtime expectations.

---

### 2. Drop Linux capabilities and disable privilege escalation where compatible

Potential future controls:

- `allowPrivilegeEscalation: false`
- dropping unnecessary capabilities
- avoiding privileged runtime assumptions

Only after workload compatibility review.

---

### 3. Disable automatic service account token mounting where not needed

Current manifests do not explicitly set service account token behavior.

Potential later review:
- `automountServiceAccountToken: false` for workloads that do not need Kubernetes API access

This is useful hardening, but not required to complete the current pre-Helm cleanup phase.

---

### 4. Ingress TLS and stricter routing policy

Current ingress is HTTP-only on Traefik `web`.

Later production direction may include:

- TLS termination
- stricter ingress annotations
- host/path restrictions
- possibly different public posture for Grafana vs ingest

---

### 5. NetworkPolicy review

Network policies were not part of this review pass.

Later production review may consider restricting pod-to-pod traffic more explicitly.

This is a valid future hardening topic, but not required to finish the current cleanup sequence.

---

## Component-by-component notes

### Hermon ingest
Current strengths:
- internal Service plus explicit Ingress
- readiness and liveness probes exist
- no literal secrets in manifest
- image pull secret is used

Current gaps:
- no resources
- no `securityContext`
- no explicit non-root posture
- TCP-only probes
- ingress is open HTTP on `web`

### Telegraf
Current strengths:
- internal-only Service
- probes exist
- secret-backed env vars
- config mounted read-only

Current gaps:
- no resources
- no `securityContext`
- no explicit non-root posture
- TCP-only probes

### Grafana
Current strengths:
- HTTP health probes are better than simple TCP
- secret-backed env vars
- internal Service plus explicit Ingress
- file-based provisioning is clean

Current gaps:
- no resources
- no `securityContext`
- no explicit non-root posture
- ingress is open HTTP on `web`

### TimescaleDB
Current strengths:
- stateful workload kind is correct
- internal-only headless Service
- secret-backed env vars
- explicit resource requests/limits
- useful readiness/liveness checks

Current gaps:
- no `securityContext`
- no explicit non-root posture in manifest
- backup and upgrade hardening remain separate concerns

---

## Current recommendation

Before calling Hermon production-packaging-ready, the minimum worthwhile hardening improvements are:

1. decide whether resource policy should remain environment-specific for now instead of being added to the shared base
2. review and add explicit `securityContext` settings where compatible
3. review non-root execution for all workloads
4. review whether ingest ingress needs tighter restrictions than the current simple HTTP exposure
5. improve probes only where it clearly adds signal without destabilizing the stack

## What does not need to happen yet

This phase does **not** require immediate implementation of:

- full production secret manager integration
- deep zero-trust networking
- advanced policy engines
- complete lockdown of every container
- large architectural changes

That is consistent with the cleanup plan: review now, implement the necessary improvements in a controlled way before production packaging.

## Final assessment

Hermon is in a reasonable place for a working k3s / Argo CD deployment.

The current hardening posture is:

- acceptable for test and cleanup stages
- partially prepared for production review
- not yet explicit enough to call production-hardened

The main next hardening wins are explicit runtime policy and explicit resource policy, not architecture redesign.

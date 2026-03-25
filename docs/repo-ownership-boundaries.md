# Hermon Repo Ownership Boundaries

## Purpose

This document defines which repo owns which kinds of files in the Hermon project.

The goal is to make the answer to “where should this file live?” clear and consistent,
while preserving the current working behavior.

## Ownership labels

### 1. Canonical
The authoritative source of truth for a file or asset.

### 2. Deployment copy
A copy kept in `hermon-gitops` only because Kubernetes packaging or mounting needs it.
It must not become a second independent source of truth.

### 3. Cluster-local only
A file or manifest that only exists to define Kubernetes, Argo CD, or cluster behavior.

---

## `hermon-ingest` owns

These belong canonically in `hermon-ingest`:

- decoder source code
- Docker build files
- local Compose files
- canonical Telegraf app-layer config
- canonical Grafana app-layer assets
- example env files
- app-facing operational documentation

### Rule of thumb
If the file defines **what the application does**, it belongs in `hermon-ingest`.

---

## `hermon-gitops` owns

These belong canonically in `hermon-gitops`:

- Deployments
- Services
- Ingresses
- StatefulSets
- secret references
- PVC/storage declarations
- Argo application wiring
- cluster-facing operational documentation

### Rule of thumb
If the file defines **how Kubernetes deploys, mounts, exposes, stores, or reconciles the app**, it belongs in `hermon-gitops`.

---

## Special case: deployment copies

Some files may appear in both repos temporarily or intentionally.

This is allowed only when:

- the canonical source lives in `hermon-ingest`
- the copy in `hermon-gitops` is needed for Kubernetes packaging or mounting
- the copy is treated as a deployment copy, not a second authority
- the canonical source path is documented next to the copy

### Required note for deployment copies

Any deployment copy in `hermon-gitops` should include a nearby note such as:

> This file is a deployment copy.  
> Canonical source: `hermon-ingest/<path>`  
> Do not evolve this independently unless the canonical source is updated first.

---

## Current boundary rules

### Telegraf
- Canonical app config: `hermon-ingest`
- Kubernetes-mounted copy: `hermon-gitops` if needed

### Grafana datasources / providers / dashboards
- Canonical app assets: `hermon-ingest`
- Kubernetes-mounted copy: `hermon-gitops` if needed

### Secrets
- Secret values: not committed to Git
- Secret references in manifests: `hermon-gitops`
- Safe example env files: `hermon-ingest`

### Documentation
- App behavior / local run / local troubleshooting: `hermon-ingest`
- Cluster deploy / Argo CD / namespace / secret creation / validation in k3s: `hermon-gitops`

---

## Decision test

Ask these in order:

1. Does this file define app behavior or app-owned config?
   - If yes, canonical home is `hermon-ingest`

2. Does this file define Kubernetes deployment or cluster wiring?
   - If yes, canonical home is `hermon-gitops`

3. Is this an app-owned file that must exist in `hermon-gitops` only for mounting or packaging?
   - If yes, keep it as a deployment copy and document the canonical source

4. Is this file only relevant inside the cluster?
   - If yes, it belongs in `hermon-gitops`

---

## Anti-patterns to avoid

- editing the same config independently in both repos
- storing app-layer config only in `hermon-gitops`
- putting cluster deployment behavior into `hermon-ingest`
- duplicating docs with slightly different truth in both repos

---

## Migration posture

Boundary cleanup should prefer:

- small safe moves
- no architecture redesign
- preserving working behavior
- making ownership explicit before reducing duplication further

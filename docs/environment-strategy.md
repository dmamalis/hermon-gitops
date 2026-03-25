# Hermon environment strategy

## Purpose

This document defines the expected environments for Hermon before Helm packaging starts.

It exists so environment differences are made explicit before they are templated.

This is a planning document.
It does not redesign the current stack.

## Why this exists

Before Helm, it should be clear:

- which environments Hermon is expected to run in
- what is different in each environment
- what should stay consistent across environments
- which differences belong to configuration and packaging rather than architecture

This keeps Helm later focused on packaging, not rediscovering environment assumptions.

---

## Expected environments

Current and likely future environments:

- local Docker/Compose
- k3s test cluster
- later Minikube or equivalent dev cluster
- production cluster

This matches the current planning direction for the pre-Helm cleanup.

---

## Environment 1: local Docker/Compose

### Purpose
Local app development and quick end-to-end functional testing.

### Current deployment model
- runs from `hermon-ingest`
- uses Docker Compose
- uses local `compose/env/*.env`
- mounts canonical app-layer config directly from the repo

### Characteristics
- simplest developer workflow
- fastest place to test decoder/app changes
- not a Kubernetes environment
- not the reference for cluster-specific operational behavior

### What is environment-specific here
- Compose files
- local env files
- localhost-facing ports
- direct bind mounts of app-owned config
- local developer credentials and test values

### What should stay consistent with cluster environments
- ingest contract
- decoder behavior
- Telegraf config shape
- Grafana provisioning assets
- environment variable names used by the app/config
- overall data flow expectations

### Current ownership
- canonical home: `hermon-ingest`

---

## Environment 2: k3s test cluster

### Purpose
Current real cluster deployment and primary pre-Helm reference environment.

### Current deployment model
- runs from `hermon-gitops`
- reconciled by Argo CD
- uses Kubernetes manifests and Kustomize
- uses manually created cluster secrets
- uses Traefik ingress and LAN DNS names

### Characteristics
- closest current reference for real deployment behavior
- practical testbed for packaging, rollout, storage, and access decisions
- should remain simple and understandable

### What is environment-specific here
- Kubernetes manifests
- Ingress hosts
- cluster secret names
- PVC and storage behavior
- cluster networking and DNS
- Traefik ingress behavior
- image pull secret setup

### What should stay consistent with other environments
- app contract from `hermon-ingest`
- Telegraf and Grafana canonical assets
- stack topology
- secret variable names where practical
- validation expectations

### Current ownership
- cluster-facing home: `hermon-gitops`

---

## Environment 3: later Minikube or equivalent dev cluster

### Purpose
Possible future developer-oriented Kubernetes environment.

### Current status
- not implemented
- explicitly out of scope for the immediate cleanup plan
- should not drive today’s packaging structure

### Why it still matters conceptually
- it is a likely future environment
- it may differ from k3s in ingress, storage, and local access patterns
- it is useful to recognize it now so k3s-specific assumptions are not mistaken for universal ones

### Likely differences from k3s
- ingress setup
- storage class behavior
- local access workflow
- cluster bootstrap steps
- optional simplifications for developer use

### Planning rule
- acknowledge this environment
- do not design around it yet
- do not complicate current manifests just to support it prematurely

---

## Environment 4: production cluster

### Purpose
Future broader deployment and operational target.

### Current status
- not implemented yet
- not fully defined yet
- pre-Helm cleanup is intended to prepare for this later step

### Likely production-specific concerns
- stricter secret handling
- TLS and ingress hardening
- backup expectations
- rollout discipline
- stronger resource policy
- clearer operational ownership
- possibly different storage and DNS assumptions

### Planning rule
- production should influence what becomes configurable
- production should not force premature complexity into the current cleanup

---

## What differs by environment

These are good candidates to vary by environment later:

- image tags
- image pull secret names
- ingress enabled/disabled state
- ingress hosts
- cluster secret names
- storage size
- storage class
- resource policy
- service exposure details
- optional input enablement
- local developer env values

These are the kinds of differences that should later map cleanly into Helm values or overlays.

---

## What should remain consistent across environments

These should stay as stable as possible:

- overall architecture
- ingest request/payload contract
- decoded field naming
- Telegraf canonical config structure
- Grafana canonical provisioning/dashboard assets
- repo ownership boundaries
- secret values staying out of Git
- the principle that app-layer config is canonical in `hermon-ingest`
- the principle that cluster/deployment wiring is canonical in `hermon-gitops`

---

## Packaging rule before Helm

Until Helm exists:

- local Docker/Compose stays the local app/developer environment
- k3s GitOps stays the cluster deployment reference environment
- future environments should be documented before they are templated
- shared base decisions should not be polluted with assumptions that only belong to one environment

This is especially important for:
- resource policy
- ingress behavior
- secret names
- storage settings

---

## Environment separation guidance

### Safe to keep shared
- app contract
- canonical app-layer config
- validation logic
- rollout principles
- repo boundary rules

### Better treated as environment-specific
- secret object names
- ingress hostnames
- storage sizing
- resource settings
- cluster bootstrap details
- local developer convenience settings

---

## Current recommendation

Use this mental model:

### `hermon-ingest`
Owns:
- the app
- the app contract
- the local Compose environment
- canonical Telegraf and Grafana app-layer assets

### `hermon-gitops`
Owns:
- the current k3s cluster deployment model
- Argo/Kustomize packaging
- cluster-specific access, secrets, persistence, and rollout docs

### Future Helm
Should package:
- the shared deployable structure
- the known environment differences
- without redesigning the application or repo boundaries

---

## Final assessment

Hermon currently has one real local environment and one real cluster environment.

That is enough to define the environment strategy now.

The key rule before Helm is:

- document environment differences first
- template them later
- do not confuse current k3s-specific choices with universal packaging truth

# hermon-gitops

Kubernetes / GitOps deployment repository for Hermon.

## Scope
This repository contains:
- Argo CD applications
- Kubernetes manifests
- Kustomize structure
- cluster deployment configuration

## Out of scope
This repository does not contain:
- ingest / decoder source code
- Docker-oriented development workflow
- application business logic

Those live in the separate `hermon-ingest` repository.

## Initial goal
Deploy a minimal Hermon stack to k3s with Argo CD:
- TimescaleDB
- ingest service
- Telegraf
- Grafana


## Sync rule with `hermon-ingest`

Some application-facing configuration is authored first in the `hermon-ingest` repository and then mirrored into this GitOps repository.

Current rule:
- `telegraf/telegraf.conf` in `hermon-ingest` is the canonical Telegraf config
- Grafana provisioning and dashboard files in `hermon-ingest/grafana/` are the canonical app-layer Grafana assets
- when those files change, the equivalent ConfigMap-backed manifests in `hermon-gitops` must be updated in the same change set or immediately after

This keeps application config aligned with the deployed Kubernetes manifests.


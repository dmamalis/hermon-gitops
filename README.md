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

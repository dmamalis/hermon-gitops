# Hermon GitOps Repository Instructions

## Purpose
This repository contains the Kubernetes / GitOps deployment configuration for Hermon.

It includes:
- Kubernetes manifests
- Kustomize bases and overlays
- Argo CD Application definitions
- cluster deployment configuration

It does not include:
- ingest / decoder application source code
- Docker-based local development workflow
- application business logic

Those belong in the separate `hermon-ingest` repository.

## Architecture boundary
This repository consumes the application contract defined by `hermon-ingest`.

That means:
- image names and tags come from the app repo or registry workflow
- application ports, env vars, and health endpoints should match the app repo
- this repo should not redefine core ingest behavior

## Working rules
- Prefer small, reviewable changes.
- Keep manifests readable and explicit.
- Favor clarity over cleverness.
- Avoid unnecessary production-grade complexity.
- Prefer plain manifests and Kustomize before introducing Helm.
- Introduce ingress only after internal connectivity works.
- Treat TimescaleDB as stateful.
- Treat ingest and Telegraf as stateless single-replica services initially.
- Treat Grafana as disposable where possible through provisioning.

## Repository structure
- `apps/` contains Argo CD Application manifests.
- `hermon/base/` contains the base Kubernetes resources.
- Add overlays only when there is a real need.

## Configuration rules
- Use ConfigMaps for non-sensitive configuration.
- Use Secrets for passwords, tokens, and credentials.
- Do not hard-code real secrets in manifests.
- Prefer Kubernetes service DNS names over fixed IPs.

## Before editing
First understand:
- which component is being deployed
- which service depends on which internal DNS name
- what config belongs in ConfigMap vs Secret
- whether the change belongs here or in `hermon-ingest`

## Current deployment goal
The first target is the same validated vertical slice already proven locally:

TimescaleDB -> hermon-ingest -> Telegraf -> Grafana

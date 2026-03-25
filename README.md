# hermon-gitops

GitOps environment repository for Hermon.

## Active role

This repository now owns the **environment-specific deployment side** of Hermon:

- Argo CD Application definitions
- environment values files
- support manifests that remain cluster-local
- cluster-facing operational documentation

## Active deployment model

Hermon is now deployed through:

- chart/package source from `hermon-ingest`
- environment values from `hermon-gitops/hermon/values/`
- support manifests from `hermon-gitops/hermon/support/`

## What stays here

This repository should keep:

- Argo CD applications
- environment-specific values
- namespace/support manifests
- cluster-local config such as `hermon-ingest-config`
- cluster-facing docs

## What no longer belongs as the active model

This repository is no longer the primary home of the full app stack manifests.

The previous Kustomize app stack has been archived under:

- `hermon/archive/base-kustomize/`

## Boundary

- `hermon-ingest` owns app behavior, packaged deploy content, and local Docker/Compose workflow
- `hermon-gitops` owns environment choices, promotion, and cluster-side concerns

# Hermon archived deployment model

This folder preserves the pre-chart Kustomize deployment model for reference.

It is no longer the active deployment path.

Current active model:
- chart/package source: `hermon-ingest/deploy/charts/hermon`
- GitOps environment support: `hermon/support`
- GitOps environment values: `hermon/values/`

Why this archive exists:
- preserve the previous working manifests for rollback/reference
- avoid carrying two "current" deployment models in parallel

Do not treat `archive/base-kustomize/` as the active deployment source.

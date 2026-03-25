# Grafana deployment assets

These files are deployment copies used by `hermon-gitops` for Kustomize and ConfigMap packaging.

Canonical source files live in `hermon-ingest`:

- `grafana/provisioning/datasources/hermon-timescale.yaml`
- `grafana/provisioning/dashboards/hermon-dashboards.yaml`
- `grafana/dashboards/hermon-v3-timescale.json`

Rules:

- update the canonical source in `hermon-ingest` first
- then sync the corresponding file here
- do not evolve these copies independently

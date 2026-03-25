# Hermon Repo Ownership Inventory

This file tracks boundary decisions between `hermon-ingest` and `hermon-gitops`.

## Labels

- **canonical** = authoritative source of truth
- **deployment copy** = copy kept in `hermon-gitops` for Kubernetes packaging or mounting
- **cluster-local only** = exists only for Kubernetes/Argo/cluster behavior

---

## Telegraf

| File / category | Current repo | Should be canonical in | Label | Action | Notes |
|---|---|---|---|---|---|
| `telegraf/telegraf.conf` | hermon-ingest | hermon-ingest | canonical | keep | canonical base Telegraf app config |
| `telegraf/conf.available/inputs-mqtt-public.conf` | hermon-ingest | hermon-ingest | canonical | keep | optional canonical input fragment |
| `telegraf/conf.available/inputs-mqtt-ttn.conf` | hermon-ingest | hermon-ingest | canonical | keep | optional canonical input fragment |
| `compose/env/telegraf.env.example` | hermon-ingest | hermon-ingest | canonical | keep | app-facing safe example env |
| `telegraf/README.md` | hermon-ingest | hermon-ingest | canonical | keep | app-facing Telegraf documentation |
| `compose/archive/telegraf.compose.yaml` | hermon-ingest | hermon-ingest | canonical | keep | archive/local historical asset, not cluster wiring |
| `telegraf/archive/full-legacy.conf` | hermon-ingest | hermon-ingest | canonical | keep | archived historical reference, not active deployment source |
| `hermon/base/telegraf/assets/telegraf.conf` | hermon-gitops | hermon-ingest | deployment copy | keep and mark | deployment copy for Kustomize/ConfigMap packaging |
| `hermon/base/telegraf/assets/conf.available/inputs-mqtt-public.conf` | hermon-gitops | hermon-ingest | deployment copy | keep and mark | deployment copy of canonical fragment |
| `hermon/base/telegraf/assets/conf.available/inputs-mqtt-ttn.conf` | hermon-gitops | hermon-ingest | deployment copy | keep and mark | deployment copy of canonical fragment |
| `hermon/base/telegraf/deployment.yaml` | hermon-gitops | hermon-gitops | cluster-local only | keep | Kubernetes deployment wiring |
| `hermon/base/telegraf/service.yaml` | hermon-gitops | hermon-gitops | cluster-local only | keep | Kubernetes service definition |
| `hermon/base/telegraf/kustomization.yaml` | hermon-gitops | hermon-gitops | cluster-local only | keep | Kustomize packaging and ConfigMap generation |
| secret refs in Telegraf manifests | hermon-gitops | hermon-gitops | cluster-local only | keep | cluster secret references belong in deployment repo |
| Telegraf volume mounts / manifest wiring | hermon-gitops | hermon-gitops | cluster-local only | keep | deployment-only concern |

## Telegraf boundary assessment

Current Telegraf ownership is already close to the desired target model:

- canonical app-layer config lives in `hermon-ingest`
- Kubernetes wiring lives in `hermon-gitops`
- `hermon-gitops` keeps file-based deployment copies for packaging and mounting

Follow-up rule:

- update canonical Telegraf config in `hermon-ingest` first
- then sync the corresponding deployment copy in `hermon-gitops`
- do not evolve the GitOps copy independently

---

## Grafana

| File / category | Current repo | Should be canonical in | Label | Action | Notes |
|---|---|---|---|---|---|
| `grafana/provisioning/datasources/hermon-timescale.yaml` | hermon-ingest | hermon-ingest | canonical | keep | canonical datasource provisioning, env-based for both local and cluster use |
| `grafana/provisioning/dashboards/hermon-dashboards.yaml` | hermon-ingest | hermon-ingest | canonical | keep | canonical dashboard provider provisioning |
| `grafana/dashboards/hermon-v3-timescale.json` | hermon-ingest | hermon-ingest | canonical | keep | canonical dashboard asset |
| `compose/env/grafana.env.example` | hermon-ingest | hermon-ingest | canonical | keep | app-facing safe example env |
| `compose/archive/grafana.compose.yaml` | hermon-ingest | hermon-ingest | canonical | keep | archive/local historical asset, not cluster wiring |
| `hermon/base/grafana/assets/provisioning/datasources/hermon-timescale.yaml` | hermon-gitops | hermon-ingest | deployment copy | keep and mark | deployment copy for Kustomize/ConfigMap packaging |
| `hermon/base/grafana/assets/provisioning/dashboards/hermon-dashboards.yaml` | hermon-gitops | hermon-ingest | deployment copy | keep and mark | deployment copy of canonical provider config |
| `hermon/base/grafana/assets/dashboards/hermon-v3-timescale.json` | hermon-gitops | hermon-ingest | deployment copy | keep and mark | deployment copy of canonical dashboard asset |
| `hermon/base/grafana/deployment.yaml` | hermon-gitops | hermon-gitops | cluster-local only | keep | Kubernetes deployment wiring |
| `hermon/base/grafana/service.yaml` | hermon-gitops | hermon-gitops | cluster-local only | keep | Kubernetes service definition |
| `hermon/base/grafana/ingress.yaml` | hermon-gitops | hermon-gitops | cluster-local only | keep | Kubernetes ingress definition |
| `hermon/base/grafana/kustomization.yaml` | hermon-gitops | hermon-gitops | cluster-local only | keep | Kustomize packaging and ConfigMap generation |
| grafana secret refs in manifests | hermon-gitops | hermon-gitops | cluster-local only | keep | cluster secret references belong in deployment repo |
| grafana PVC/storage declarations | hermon-gitops | hermon-gitops | cluster-local only | keep | cluster persistence concern |
| grafana service/ingress/deployment wiring | hermon-gitops | hermon-gitops | cluster-local only | keep | deployment-only concern |

## Grafana boundary assessment

Current Grafana ownership is close to the desired target model:

- canonical app-layer assets live in `hermon-ingest`
- Kubernetes wiring lives in `hermon-gitops`
- `hermon-gitops` keeps file-based deployment copies for packaging and mounting

Follow-up rule:

- update canonical Grafana assets in `hermon-ingest` first
- then sync the corresponding deployment copy in `hermon-gitops`
- do not evolve the GitOps copy independently

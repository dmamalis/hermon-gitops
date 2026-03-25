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

---

## Env examples

| File / category | Current repo | Should be canonical in | Label | Action | Notes |
|---|---|---|---|---|---|
| `compose/env/decoder.env.example` | hermon-ingest | hermon-ingest | canonical | keep | app-facing decoder example env |
| `compose/env/grafana.env.example` | hermon-ingest | hermon-ingest | canonical | keep | app-facing Grafana example env |
| `compose/env/telegraf.env.example` | hermon-ingest | hermon-ingest | canonical | keep | app-facing Telegraf example env |
| `compose/env/timescale.env.example` | hermon-ingest | hermon-ingest | canonical | keep | app-facing local Timescale example env |
| cluster secret references in manifests | hermon-gitops | hermon-gitops | cluster-local only | keep | secret refs belong in deployment repo |
| committed `*.env.example` files in `hermon-gitops` | none currently | hermon-ingest by default | n/a | none | current boundary is clean |

## Env example boundary assessment

Current env example ownership is clean:

- safe example env files live in `hermon-ingest`
- cluster secret refs stay in `hermon-gitops`
- no duplicate env-example layer currently exists in GitOps

Follow-up rule:

- new app-facing example env files should default to `hermon-ingest`
- `hermon-gitops` should reference secrets, not become a second home for example env files

---

## Documentation

| File / category | Current repo | Should be canonical in | Label | Action | Notes |
|---|---|---|---|---|---|
| `README.md` (root, ingest) | hermon-ingest | hermon-ingest | canonical | keep | root app/local scope README |
| `AGENTS.md` (ingest) | hermon-ingest | hermon-ingest | canonical | keep | repo-local instructions for ingest repo |
| `compose/README.md` | hermon-ingest | hermon-ingest | canonical | keep | local Compose workflow documentation |
| `decoder/README.md` | hermon-ingest | hermon-ingest | canonical | keep | app component documentation |
| `telegraf/README.md` | hermon-ingest | hermon-ingest | canonical | keep | app-layer Telegraf documentation |
| `docs/image-versioning-policy.md` | hermon-ingest | hermon-ingest | canonical | keep for now | shared cross-repo policy doc currently authored here; GitOps should reference rather than duplicate |
| `README.md` (root, gitops) | hermon-gitops | hermon-gitops | canonical | keep | root cluster/deployment scope README |
| `AGENTS.md` (gitops) | hermon-gitops | hermon-gitops | canonical | keep | repo-local instructions for GitOps repo |
| `hermon/docs/access-and-validation.md` | hermon-gitops | hermon-gitops | canonical | keep | cluster-facing validation and access doc |
| `docs/repo-ownership-boundaries.md` | hermon-gitops | hermon-gitops | canonical | keep | repo-boundary policy doc |
| `docs/repo-ownership-inventory.md` | hermon-gitops | hermon-gitops | canonical | keep | working ownership inventory |
| `hermon/base/telegraf/assets/README.md` | hermon-gitops | hermon-gitops | canonical | keep | deployment-copy guidance for Telegraf assets |
| `hermon/base/grafana/assets/README.md` | hermon-gitops | hermon-gitops | canonical | keep | deployment-copy guidance for Grafana assets |

## Documentation boundary assessment

Current documentation ownership is mostly clean:

- app-facing and local workflow docs live in `hermon-ingest`
- cluster-facing deployment and validation docs live in `hermon-gitops`
- repo-local instruction files stay in their respective repos

Notable ambiguous item:

- `hermon-ingest/docs/image-versioning-policy.md` is a cross-repo policy document
- safest current choice is to keep it canonical in `hermon-ingest`
- `hermon-gitops` should reference this policy rather than duplicate it

Follow-up rule:

- if a doc explains how to run, build, configure, or understand the app, it belongs in `hermon-ingest`
- if a doc explains how the cluster deploys, exposes, validates, or reconciles Hermon, it belongs in `hermon-gitops`
- if a doc is cross-repo policy, keep a single canonical copy and link to it from the other repo

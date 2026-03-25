# Hermon future Helm values model

## Purpose

This document defines the values that should likely become configurable when Hermon is later packaged as Helm charts.

This is a planning document only.

It does not introduce Helm yet.
It exists so Helm later becomes a packaging step instead of a redesign step.

## Current posture

Hermon already works on k3s with Argo CD.

The goal here is not to redesign the stack.
The goal is to record which parts should later become configurable and which parts should likely stay fixed by default.

---

## Value design rules

Prefer values only for things that are likely to vary between environments or deployments.

Do not over-template internal details that are stable and easier to keep explicit.

Default rule:

- make environment-dependent things configurable
- keep structural manifest details fixed unless there is a clear reason to vary them

---

## Likely future Helm values

### 1. Hermon ingest image

These should become configurable:

- image repository
- image tag
- image pull policy
- image pull secret name

Suggested shape:

- `hermonIngest.image.repository`
- `hermonIngest.image.tag`
- `hermonIngest.image.pullPolicy`
- `hermonIngest.image.pullSecretName`

Why:
- first-party image versions will change often across releases and environments

---

### 2. Third-party image overrides

These may become configurable:

- Telegraf image
- Grafana image
- TimescaleDB image

Suggested shape:

- `telegraf.image.repository`
- `telegraf.image.tag`
- `grafana.image.repository`
- `grafana.image.tag`
- `timescaledb.image.repository`
- `timescaledb.image.tag`

Why:
- probably not changed often
- still useful to expose as overrides for controlled upgrades

Default posture:
- expose these, but treat them as advanced values

---

### 3. Ingress settings

These should become configurable:

- ingress enabled/disabled
- ingress hostnames
- ingress class name if needed later
- annotations if needed later

Suggested shape:

- `ingress.ingest.enabled`
- `ingress.ingest.host`
- `ingress.grafana.enabled`
- `ingress.grafana.host`

Why:
- hostnames and ingress usage are environment-dependent

Default posture:
- keep the current simple host model as default

---

### 4. Service settings

These may become configurable:

- service type
- service port only if there is a clear need

Suggested shape:

- `hermonIngest.service.type`
- `telegraf.service.type`
- `grafana.service.type`
- `timescaledb.service.type`

Why:
- most environments will probably keep `ClusterIP`
- exposing service type can still be useful for edge cases

Default posture:
- default all internal services to `ClusterIP`

---

### 5. Secret names

These should become configurable by name, not by value.

Suggested shape:

- `hermonIngest.image.pullSecretName`
- `telegraf.secretNames.db`
- `telegraf.secretNames.ttn`
- `grafana.secretName`
- `timescaledb.secretName`

Why:
- secret values should remain outside Git
- secret object names may vary by environment or installation style

Important:
- Helm values should not store real secret material in this model

---

### 6. Storage settings

These should become configurable:

- TimescaleDB storage size
- storage class name if later needed

Suggested shape:

- `timescaledb.persistence.enabled`
- `timescaledb.persistence.size`
- `timescaledb.persistence.storageClassName`

Why:
- persistence needs vary by environment

Default posture:
- keep TimescaleDB persistent by default

---

### 7. Resource requests and limits

These should become configurable for each component.

Suggested shape:

- `hermonIngest.resources`
- `telegraf.resources`
- `grafana.resources`
- `timescaledb.resources`

Why:
- resource expectations vary significantly between test and production environments

Default posture:
- keep defaults simple and conservative

---

### 8. Optional component toggles

These may become configurable:

- TTN input enabled/disabled
- public MQTT input enabled/disabled
- Grafana enabled/disabled in deployments that use an external Grafana later
- possibly Telegraf enabled/disabled only if architecture later supports alternatives

Suggested shape:

- `telegraf.inputs.ttn.enabled`
- `telegraf.inputs.publicMqtt.enabled`
- `grafana.enabled`

Why:
- some deployments may not want all current inputs or components

Default posture:
- do not invent new toggles unless there is a real deployment use case

---

### 9. Environment-specific app settings

These should become configurable where they are already part of the app contract.

Likely examples:

- ingest host/port/path if needed
- config map names only if packaging requires it
- namespace-scoped names only if needed for reuse

Suggested shape:

- `hermonIngest.config.host`
- `hermonIngest.config.port`
- `hermonIngest.config.path`

Why:
- these belong to the app contract and may vary by environment

Default posture:
- keep only the existing contract configurable
- do not introduce speculative settings

---

## What should probably stay fixed

These should probably remain explicit in templates/manifests unless a real need appears:

- probe structure
- most labels
- projected volume structure for Telegraf config
- Grafana provisioning mount layout
- basic workload kinds (`Deployment` vs `StatefulSet`)
- core service-to-service topology

Why:
- these are structural design choices, not routine deployment values

---

## Candidate values summary

### High-priority future values
- Hermon ingest image repo/tag
- ingress hosts
- ingress enabled flags
- secret names
- TimescaleDB storage size
- per-component resources

### Medium-priority future values
- third-party image overrides
- service types
- optional component toggles

### Low-priority or avoid for now
- deep structural manifest details
- speculative knobs without a real deployment use case

---

## Environment thinking before Helm

Likely environments:

- local Docker/Compose
- k3s test cluster
- later production cluster

Expected differences across environments:

- image tags
- hostnames
- secret names
- storage size
- resources
- optional ingress enablement

Expected similarities across environments:

- core app topology
- ingest to Telegraf flow
- Telegraf to TimescaleDB flow
- Grafana provisioning model
- ownership boundary between app config and deployment wiring

---

## Current recommendation before Helm

When converting to Helm later:

1. expose only the values listed here that clearly vary by environment
2. keep app-layer config canonical in `hermon-ingest`
3. keep secret values out of Git
4. do not template every field just because Helm allows it
5. prefer a small understandable values model first

---

## Result we want

When Helm work starts, the main questions should already be answered:

- what is configurable
- what stays fixed
- what varies by environment
- what must remain outside Git
- what belongs to app config vs deployment wiring

That way Helm becomes mostly packaging work, not architecture redesign.

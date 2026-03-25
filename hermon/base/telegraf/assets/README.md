# Telegraf deployment assets

These files are deployment copies used by `hermon-gitops` for Kustomize/ConfigMap packaging.

Canonical source files live in `hermon-ingest`:

- `telegraf/telegraf.conf`
- `telegraf/conf.available/inputs-mqtt-public.conf`
- `telegraf/conf.available/inputs-mqtt-ttn.conf`

Rules:

- update the canonical source in `hermon-ingest` first
- then sync the corresponding file here
- do not evolve these copies independently

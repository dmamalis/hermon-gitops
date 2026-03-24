# Hermon access and validation

## Access points

Current LAN hostnames:

- `grafana.hermon` -> Grafana UI through Traefik Ingress
- `ingest.hermon` -> Hermon ingest HTTP endpoint through Traefik Ingress

## Core in-cluster flow

- `ingest.hermon` -> `hermon-ingest`
- `hermon-ingest` -> `telegraf`
- `telegraf` -> `timescaledb`
- `grafana.hermon` -> Grafana -> TimescaleDB datasource

## Basic validation flow

### 1. Ingest endpoint
Send a real payload to the public ingest hostname:

~~~bash
curl -i -X POST http://ingest.hermon/ \
  -H 'Content-Type: application/json' \
  -H 'X-Device-ID: E8DB84071451' \
  -d '{"data":"016700EA"}'
~~~

### 2. Database verification
Confirm rows are landing in TimescaleDB:

~~~bash
KUBECONFIG=~/.kube/rasp-k3s.yaml kubectl exec -n hermon timescaledb-0 -- \
  psql -U postgres -d tsdb -c 'select time, device, source from data order by time desc limit 10;'
~~~

### 3. Grafana verification
Open:

- `http://grafana.hermon`

Check:
- login works
- datasource `Hermon Timescale` exists
- dashboard folder `Hermon` exists
- panels load with seeded data

## Notes

- `hermon-ingest` is exposed at path `/`, so devices should post to `http://ingest.hermon/`
- Grafana and ingest are exposed via Traefik Ingress, not via port-forward as the normal access path

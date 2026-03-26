# Hermon Minikube dev bootstrap

## Goal

Bring up a reproducible local dev cluster that matches the production-shaped flow:

- chart/package from `hermon-ingest`
- environment values from `hermon-gitops`
- Argo CD inside Minikube

## Bootstrap order

### 1. Start Minikube and install Argo CD

Use:

~~~bash
scripts/bootstrap-minikube-argo.sh
~~~

### 2. Prepare a dedicated GitHub SSH key for Argo CD

Important rules:

- use a dedicated key for Minikube Argo access
- do not use a passphrase-protected key
- the key must have read access to both:
  - `hermon-ingest`
  - `hermon-gitops`

Recommended example:

~~~bash
ssh-keygen -t ed25519 -f ~/.ssh/hermon_minikube_argocd -C "hermon-minikube-argo-$(hostname)" -N ""
~~~

Then add the public key to the GitHub account or machine user that can read both repos:

~~~bash
cat ~/.ssh/hermon_minikube_argocd.pub
~~~

### 3. Install Argo repo credentials

Use:

~~~bash
./scripts/bootstrap-argocd-github-creds.sh ~/.ssh/hermon_minikube_argocd
~~~

### 4. Bootstrap Hermon runtime secrets

Before applying the dev application, create the required runtime secrets in `hermon-dev`.

Recommended approach:

1. Copy the local example env template.
2. Fill in real values locally.
3. Create the secrets in the target namespace using a local bootstrap script or `kubectl create secret`.

Example local preparation:

~~~bash
cp hermon/examples/dev-secrets.env.example hermon/examples/dev-secrets.env
# edit hermon/examples/dev-secrets.env locally
~~~

Required secrets:

- `timescaledb-auth`
- `telemetry-db-secret`
- `grafana-secret`
- `telegraf-ttn-secret`
- `ghcr-pull-secret`

### 5. Apply the dev application

Use:

~~~bash
kubectl --context hermon-dev apply -f apps/hermon-dev.yaml
~~~

### 6. Refresh and inspect

Use:

~~~bash
kubectl --context hermon-dev -n argocd annotate application hermon-dev \
  argocd.argoproj.io/refresh=hard --overwrite

kubectl --context hermon-dev -n argocd get application hermon-dev

kubectl --context hermon-dev -n argocd get application hermon-dev -o yaml | sed -n '/status:/,$p'
~~~

## Current dev environment paths

- values: `hermon/values/dev-minikube.yaml`
- support manifests: `hermon/support-dev/`
- Argo app: `apps/hermon-dev.yaml`

## First validation target

Do not start with ingress.

First validate that:

- Argo can fetch both repos
- the app syncs
- pods become healthy
- Grafana and ingest can be reached with port-forward

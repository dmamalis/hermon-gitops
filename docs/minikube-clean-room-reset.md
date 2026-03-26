# Hermon Minikube clean-room reset

This document wipes the local `hermon-dev` Minikube dev environment and rebuilds it from scratch.

It also cleans:

- local untracked dev secrets file
- standalone kubeconfig export for external tools
- optional k9s cluster cache entries for `hermon-dev`

The GitHub SSH key for Argo CD is assumed to already exist locally:
- `~/.ssh/hermon_minikube_argocd`
- `~/.ssh/hermon_minikube_argocd.pub`

## Full wipe

Use:

~~~bash
./scripts/wipe-hermon-dev-minikube.sh
~~~

What it removes:

- Minikube profile `hermon-dev`
- kubeconfig context / cluster / user entries named `hermon-dev`
- local file `hermon/examples/dev-secrets.env`
- standalone kubeconfig export `~/.kube/hermon-dev.yaml`
- optional k9s cluster cache directories for `hermon-dev`

## Rebuild

Use:

~~~bash
scripts/bootstrap-minikube-argo.sh
./scripts/bootstrap-argocd-github-creds.sh ~/.ssh/hermon_minikube_argocd

cp hermon/examples/dev-secrets.env.example hermon/examples/dev-secrets.env
${EDITOR:-nano} hermon/examples/dev-secrets.env

./scripts/bootstrap-hermon-dev-secrets.sh hermon/examples/dev-secrets.env

kubectl --context hermon-dev apply -f apps/hermon-dev.yaml
kubectl --request-timeout=10s --context hermon-dev -n argocd annotate application hermon-dev \
  argocd.argoproj.io/refresh=hard --overwrite
~~~

## Watch deployment

~~~bash
kubectl --context hermon-dev -n hermon-dev get pods -w
kubectl --context hermon-dev -n argocd get application hermon-dev -w
~~~

## Export standalone kubeconfig for k9s / Lens

Use:

~~~bash
./scripts/export-hermon-dev-kubeconfig.sh
~~~

This writes:

- `~/.kube/hermon-dev.yaml`

Examples:

~~~bash
KUBECONFIG=~/.kube/hermon-dev.yaml k9s
~~~

Lens and similar tools can import that file directly.

## Notes

If Docker access fails during Minikube cleanup, fix local Docker permissions or rerun with sudo available.

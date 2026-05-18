## UPDATE

```bash
kubectl apply -f infra/traefik/overlays/forgejo-ssh.yaml
kubectl apply -f k8s/apps/dozzle/deployment.yaml
kubectl apply -f k8s/apps/forgejo/valkey.yaml

helm upgrade cert-manager oci://quay.io/jetstack/charts/cert-manager -n cert-manager -f k8s/infra/cert-manager/values.yaml
helm upgrade forgejo oci://code.forgejo.org/forgejo-helm/forgejo -n apps-forgejo -f k8s/apps/forgejo/values.yaml
helm upgrade ntfy k8s/apps/ntfy -n apps-ntfy
helm upgrade vikunja oci://ghcr.io/go-vikunja/helm-chart/vikunja -n apps-vikunja -f k8s/apps/vikunja/values.yaml
helm upgrade zipline k8s/apps/zipline -n apps-zipline
helm upgrade zot project-zot/zot -n apps-zot -f k8s/apps/zot/values.yaml

```

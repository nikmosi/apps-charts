## Apply

```bash
kubectl apply -f k8s/infra/traefik/overlays/forgejo-ssh.yaml
kubectl apply -f k8s/infra/certs/01-cloudflare-api-token-secret.yaml
kubectl apply -f k8s/infra/certs/02-cluster-issuer.yaml
kubectl apply -f k8s/infra/certs/03-wildcard-xinfra-ru-certificate.yaml

helm upgrade --install cert-manager oci://quay.io/jetstack/charts/cert-manager -n cert-manager -f k8s/infra/cert-manager/values.yaml
helm upgrade --install reflector emberstack/reflector -n reflector -f k8s/infra/reflector/values.yaml

helm upgrade --install dozzle k8s/apps/dozzle -n monitoring
helm upgrade --install forgejo k8s/apps/forgejo -n apps-forgejo
helm upgrade --install ntfy k8s/apps/ntfy -n apps-ntfy
helm upgrade --install vikunja oci://ghcr.io/go-vikunja/helm-chart/vikunja -n apps-vikunja -f k8s/apps/vikunja/values.yaml
helm upgrade --install zipline k8s/apps/zipline -n apps-zipline
helm upgrade --install zot project-zot/zot -n apps-zot -f k8s/apps/zot/values.yaml
```

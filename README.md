## Apply

```bash
kubectl apply -f k8s/infra/traefik/overlays/forgejo-ssh.yaml
kubectl apply -f k8s/infra/certs/01-cloudflare-api-token-secret.yaml
kubectl apply -f k8s/infra/certs/02-cluster-issuer.yaml
kubectl apply -f k8s/infra/certs/03-wildcard-xinfra-ru-certificate.yaml

helm upgrade --install cert-manager oci://quay.io/jetstack/charts/cert-manager -n cert-manager -f k8s/infra/cert-manager/values.yaml
helm upgrade --install reflector emberstack/reflector -n reflector -f k8s/infra/reflector/values.yaml

kubectl create namespace apps-lldap --dry-run=client -o yaml | kubectl apply -f -
kubectl get secret lldap-secrets -n apps-lldap >/dev/null 2>&1 || kubectl -n apps-lldap create secret generic lldap-secrets --from-literal=lldap-jwt-secret="$(head -c 48 /dev/urandom | base64 | tr -d '\n')" --from-literal=lldap-ldap-user-pass="$(head -c 24 /dev/urandom | base64 | tr -d '\n')" --from-literal=base-dn='dc=xinfra,dc=ru'
kubectl get secret lldap-user-passwords -n apps-lldap >/dev/null 2>&1 || kubectl -n apps-lldap create secret generic lldap-user-passwords --from-literal=authelia-bind-password="$(head -c 24 /dev/urandom | base64 | tr -d '\n')" --from-literal=forgejo-password="$(head -c 24 /dev/urandom | base64 | tr -d '\n')" --from-literal=nikmosi-password="$(head -c 24 /dev/urandom | base64 | tr -d '\n')" --from-literal=zot-reader-password="$(head -c 24 /dev/urandom | base64 | tr -d '\n')"
helm upgrade --install lldap oci://ghcr.io/alexmorbo/helm-charts/lldap --version 1.0.8 -n apps-lldap --create-namespace -f k8s/apps/lldap/values.yaml
kubectl apply -f k8s/apps/lldap/ingress.yaml
kubectl apply -f k8s/apps/lldap/bootstrap-config.yaml
kubectl delete job lldap-bootstrap -n apps-lldap --ignore-not-found
kubectl apply -f k8s/apps/lldap/bootstrap-job.yaml
kubectl wait --for=condition=complete job/lldap-bootstrap -n apps-lldap --timeout=120s

kubectl create namespace apps-authelia --dry-run=client -o yaml | kubectl apply -f -
kubectl get secret authelia-ldap -n apps-authelia >/dev/null 2>&1 || kubectl -n apps-authelia create secret generic authelia-ldap --from-literal=password="$(kubectl get secret lldap-user-passwords -n apps-lldap -o jsonpath='{.data.authelia-bind-password}' | base64 -d)"
helm upgrade --install authelia authelia/authelia -n apps-authelia -f k8s/apps/authelia/values.yaml
helm upgrade --install adguard k8s/apps/adguard -n apps-adguard --create-namespace
helm upgrade --install dozzle k8s/apps/dozzle -n monitoring
helm upgrade --install forgejo k8s/apps/forgejo -n apps-forgejo
helm upgrade --install goldilocks fairwinds-stable/goldilocks -n apps-goldilocks -f k8s/apps/goldilocks/values.yaml
helm upgrade --install kube-prometheus-stack oci://ghcr.io/prometheus-community/charts/kube-prometheus-stack -n apps-kube-prometheus-stack -f k8s/apps/kube-prometheus-stack/values.yaml
helm upgrade --install ntfy k8s/apps/ntfy -n apps-ntfy
helm upgrade --install trivy-operator aqua/trivy-operator -n trivy-system -f k8s/apps/trivy-operator/values.yaml
helm upgrade --install vaultwarden vaultwarden/vaultwarden -n apps-warden -f k8s/apps/vaultwarden/values.yaml
helm upgrade --install vikunja oci://ghcr.io/go-vikunja/helm-chart/vikunja -n apps-vikunja -f k8s/apps/vikunja/values.yaml
helm upgrade --install zipline k8s/apps/zipline -n apps-zipline
kubectl create namespace apps-zot --dry-run=client -o yaml | kubectl apply -f -
kubectl get secret zot-ldap -n apps-zot >/dev/null 2>&1 || kubectl -n apps-zot create secret generic zot-ldap --from-literal=config-ldap-credentials.json="$(jq -cn --arg bindDN 'uid=authelia,ou=people,dc=xinfra,dc=ru' --arg bindPassword "$(kubectl get secret lldap-user-passwords -n apps-lldap -o jsonpath='{.data.authelia-bind-password}' | base64 -d)" '{bindDN:$bindDN,bindPassword:$bindPassword}')"
helm upgrade --install zot project-zot/zot -n apps-zot -f k8s/apps/zot/values.yaml

helm upgrade --install gitlab-runner gitlab/gitlab-runner -n gitlab-runner -f k8s/apps/gitlab-runner/values.yaml
helm upgrade --install twitch-sub-bot k8s/apps/twitch-sub-bot -n apps-twitch-sub-bot
helm upgrade --install traffic-noise k8s/apps/locust -n apps-noise --create-namespace
```

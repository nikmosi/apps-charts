## Required cluster secrets

Create or rotate these Kubernetes Secrets outside Git before applying the workloads.
The commands below read values from environment variables or local files and do
not write plaintext secret material into the repository.

```bash
kubectl create namespace cert-manager --dry-run=client -o yaml | kubectl apply -f -
kubectl -n cert-manager create secret generic cloudflare-api-token-secret \
  --from-literal=api-token="${CLOUDFLARE_API_TOKEN:?Set CLOUDFLARE_API_TOKEN}" \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl create namespace apps-authentik --dry-run=client -o yaml | kubectl apply -f -
kubectl -n apps-authentik create secret generic authentik-config \
  --from-literal=AUTHENTIK_SECRET_KEY="${AUTHENTIK_SECRET_KEY:?Set AUTHENTIK_SECRET_KEY}" \
  --from-literal=AUTHENTIK_POSTGRESQL__PASSWORD="${AUTHENTIK_POSTGRESQL_PASSWORD:?Set AUTHENTIK_POSTGRESQL_PASSWORD}" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl -n apps-authentik create secret generic authentik-postgresql \
  --from-literal=password="${AUTHENTIK_POSTGRESQL_PASSWORD:?Set AUTHENTIK_POSTGRESQL_PASSWORD}" \
  --from-literal=postgres-password="${AUTHENTIK_POSTGRES_ADMIN_PASSWORD:-${AUTHENTIK_POSTGRESQL_PASSWORD:?Set AUTHENTIK_POSTGRESQL_PASSWORD}}" \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl create namespace apps-forgejo --dry-run=client -o yaml | kubectl apply -f -
kubectl -n apps-forgejo create secret generic forgejo-admin-external \
  --from-literal=username="${FORGEJO_ADMIN_USERNAME:-gitea_admin}" \
  --from-literal=password="${FORGEJO_ADMIN_PASSWORD:?Set FORGEJO_ADMIN_PASSWORD}" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl -n apps-forgejo create secret generic forgejo-authelia-oauth \
  --from-literal=key="${FORGEJO_AUTHELIA_CLIENT_ID:-forgejo}" \
  --from-literal=secret="${FORGEJO_AUTHELIA_CLIENT_SECRET:?Set FORGEJO_AUTHELIA_CLIENT_SECRET}" \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl create namespace apps-authelia --dry-run=client -o yaml | kubectl apply -f -
kubectl -n apps-authelia create secret generic authelia-core \
  --from-literal=session.encryption.key="${AUTHELIA_SESSION_ENCRYPTION_KEY:?Set AUTHELIA_SESSION_ENCRYPTION_KEY}" \
  --from-literal=storage.encryption.key="${AUTHELIA_STORAGE_ENCRYPTION_KEY:?Set AUTHELIA_STORAGE_ENCRYPTION_KEY}" \
  --from-literal=identity_providers.oidc.hmac.key="${AUTHELIA_OIDC_HMAC_SECRET:?Set AUTHELIA_OIDC_HMAC_SECRET}" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl -n apps-authelia create secret generic authelia-users-external \
  --from-file=users_database.yml="${AUTHELIA_USERS_DATABASE_FILE:?Set AUTHELIA_USERS_DATABASE_FILE}" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl -n apps-authelia create secret generic authelia-oidc \
  --from-file=jwks.authelia-rs256-2026-05.pem="${AUTHELIA_OIDC_JWKS_FILE:?Set AUTHELIA_OIDC_JWKS_FILE}" \
  --from-literal=grafana-client-secret="${AUTHELIA_GRAFANA_CLIENT_SECRET:?Set AUTHELIA_GRAFANA_CLIENT_SECRET}" \
  --from-literal=forgejo-client-secret="${FORGEJO_AUTHELIA_CLIENT_SECRET:?Set FORGEJO_AUTHELIA_CLIENT_SECRET}" \
  --from-literal=vikunja-client-secret="${VIKUNJA_AUTHELIA_CLIENT_SECRET:?Set VIKUNJA_AUTHELIA_CLIENT_SECRET}" \
  --from-literal=vaultwarden-client-secret="${AUTHELIA_VAULTWARDEN_CLIENT_SECRET:?Set AUTHELIA_VAULTWARDEN_CLIENT_SECRET}" \
  --from-literal=zot-client-secret="${ZOT_OIDC_CLIENT_SECRET:?Set ZOT_OIDC_CLIENT_SECRET}" \
  --from-literal=zipline-client-secret="${AUTHELIA_ZIPLINE_CLIENT_SECRET:?Set AUTHELIA_ZIPLINE_CLIENT_SECRET}" \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl create namespace apps-vikunja --dry-run=client -o yaml | kubectl apply -f -
cat >/tmp/vikunja-config.yml <<EOF
service:
  publicurl: https://vikunja.xinfra.ru
  enableregistration: false
auth:
  local:
    enabled: true
  openid:
    enabled: true
    providers:
      authelia:
        name: "Authelia Login"
        usernamefallback: true
        emailfallback: true
        authurl: https://auth.xinfra.ru
        clientid: ${VIKUNJA_AUTHELIA_CLIENT_ID:?Set VIKUNJA_AUTHELIA_CLIENT_ID}
        clientsecret: ${VIKUNJA_AUTHELIA_CLIENT_SECRET:?Set VIKUNJA_AUTHELIA_CLIENT_SECRET}
        scope: openid email profile
EOF
kubectl -n apps-vikunja create secret generic vikunja-config \
  --from-file=config.yml=/tmp/vikunja-config.yml \
  --dry-run=client -o yaml | kubectl apply -f -
rm -f /tmp/vikunja-config.yml

kubectl create namespace apps-zot --dry-run=client -o yaml | kubectl apply -f -
kubectl -n apps-zot create secret generic oidc-credentials \
  --from-literal=oidc-credentials.json="$(jq -cn --arg clientid "${ZOT_OIDC_CLIENT_ID:?Set ZOT_OIDC_CLIENT_ID}" --arg clientsecret "${ZOT_OIDC_CLIENT_SECRET:?Set ZOT_OIDC_CLIENT_SECRET}" '{clientid:$clientid,clientsecret:$clientsecret}')" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl -n apps-zot create secret generic zot-secret-external \
  --from-file=htpasswd="${ZOT_HTPASSWD_FILE:?Set ZOT_HTPASSWD_FILE}" \
  --from-literal=sync-auth.json="${ZOT_SYNC_AUTH_JSON:-{}}" \
  --dry-run=client -o yaml | kubectl apply -f -
```

## Apply

```bash
kubectl apply -f k8s/infra/traefik/overlays/forgejo-ssh.yaml
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
kubectl create namespace crowdsec --dry-run=client -o yaml | kubectl apply -f -
kubectl -n apps-ntfy exec statefulset/ntfy -- sh -c 'NTFY_PASSWORD="$(head -c 24 /dev/urandom | base64 | tr -d "\n")" ntfy user add --ignore-exists crowdsec'
kubectl -n apps-ntfy exec statefulset/ntfy -- ntfy access crowdsec alerts-crowdsec write-only
kubectl get secret crowdsec-ntfy-token -n crowdsec >/dev/null 2>&1 || kubectl -n crowdsec create secret generic crowdsec-ntfy-token --from-literal=NTFY_TOKEN="$(kubectl -n apps-ntfy exec statefulset/ntfy -- ntfy token add --label crowdsec crowdsec | sed -n 's/.*\(tk_[A-Za-z0-9]*\).*/\1/p' | tail -n 1)"
kubectl get secret crowdsec-keys -n crowdsec >/dev/null 2>&1 || kubectl -n crowdsec create secret generic crowdsec-keys --from-literal=ENROLL_KEY="${CROWDSEC_ENROLL_KEY:?Set CROWDSEC_ENROLL_KEY from CrowdSec Console}"
helm upgrade --install crowdsec crowdsec/crowdsec --version 0.24.0 -n crowdsec -f k8s/apps/crowdsec/values.yaml
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

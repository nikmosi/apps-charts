# twitch-sub-check Helm chart

This chart deploys the Twitch subscription watcher as a single Kubernetes
worker. It runs `src/main.py watch --interval <watch.interval>`, persists
SQLite data under `/app/var`, and connects to RabbitMQ for the event bus.

## Install

Create a values file with real credentials or point the chart at an existing
secret:

```yaml
credentials:
  existingSecret: "twitch-sub-check-credentials"
```

The secret must contain these keys by default:

```text
TWITCH_CLIENT_ID
TWITCH_CLIENT_SECRET
TELEGRAM_BOT_TOKEN
TELEGRAM_CHAT_ID
```

Install the chart:

```bash
helm upgrade --install twitch-sub-check ./charts/twitch-sub-check -f values.prod.yaml
```

## RabbitMQ

By default the chart deploys a single-node RabbitMQ StatefulSet and configures
`RABBITMQ_URL` automatically. To use an external RabbitMQ instance, disable the
embedded broker and provide the URL directly or through a secret:

```yaml
rabbitmq:
  enabled: false

eventBus:
  rabbitmq:
    externalUrlSecret:
      name: "rabbitmq-url"
      key: "RABBITMQ_URL"
```

## Persistence

The application PVC stores SQLite data at `/app/var`. The default deployment
uses `replicaCount: 1` and `strategy.type: Recreate` to avoid concurrent access
to the same SQLite database.

## Validation

```bash
helm lint ./charts/twitch-sub-check
helm template twitch-sub-check ./charts/twitch-sub-check --values ./charts/twitch-sub-check/values.yaml
```

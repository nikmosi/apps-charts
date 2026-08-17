# forgesync Helm Chart

Helm chart for deploying [forgesync](https://zot.xinfra.ru/forgesync) - an automated tool to mirror all your Forgejo repositories to GitHub or other Forgejo / Codeberg instances.

## Features

- ⏰ Periodic execution using Kubernetes **CronJob** resources.
- 🎯 Support for **multiple sync targets** within a single release (e.g. GitHub, Codeberg, secondary Forgejo).
- 🔒 **Private repositories included by default** (`--include-private`).
- 🛡️ Strict Pod and Container **SecurityContext** settings (`runAsNonRoot`, `readOnlyRootFilesystem`, `drop: ALL`).
- 🔑 Flexible secret references for API tokens (`FORGEJO_TOKEN`, `GITHUB_TOKEN`, etc.).

## Prerequisites

- Kubernetes 1.21+
- Helm 3.0+

## Quick Start

```bash
helm repo add my-repo <repo-url>
helm install forgesync k8s/charts/forgesync --set secret.create=true --set secret.data.FORGEJO_TOKEN="your-token" --set secret.data.GITHUB_TOKEN="your-github-token"
```

## Configuration

The following table lists the configurable parameters of the `forgesync` chart and their default values:

| Parameter | Description | Default |
| --- | --- | --- |
| `image.repository` | Container image repository | `zot.xinfra.ru/forgesync` |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `image.tag` | Container image tag | `v1.2.0` |
| `schedule` | Default cron schedule for all targets | `0 */4 * * *` |
| `source` | Default base URL of source Forgejo instance | `https://forgejo.example.com` |
| `defaults.includePrivate` | Include private repositories by default | `true` |
| `defaults.includeForks` | Include repository forks | `false` |
| `defaults.logLevel` | Logging level (`DEBUG`, `INFO`, `WARNING`, `ERROR`) | `INFO` |
| `defaults.dryRun` | Perform dry run without making actual changes | `false` |
| `targets` | Map of sync targets (each renders a CronJob) | `{ github: { ... } }` |
| `secret.create` | Create a chart-managed secret for tokens | `false` |

## Example: Configuring Multiple Targets

```yaml
schedule: "0 */2 * * *"
source: "https://git.mycompany.com"

targets:
  github:
    enabled: true
    target: "github"
    schedule: "0 */4 * * *"
    includePrivate: true
    includeForks: false
    env:
      - name: FORGEJO_TOKEN
        valueFrom:
          secretKeyRef:
            name: forgesync-tokens
            key: FORGEJO_TOKEN
      - name: GITHUB_TOKEN
        valueFrom:
          secretKeyRef:
            name: forgesync-tokens
            key: GITHUB_TOKEN

  codeberg:
    enabled: true
    target: "codeberg"
    schedule: "0 0 * * *"
    includePrivate: false
    env:
      - name: FORGEJO_TOKEN
        valueFrom:
          secretKeyRef:
            name: forgesync-tokens
            key: FORGEJO_TOKEN
      - name: CODEBERG_TOKEN
        valueFrom:
          secretKeyRef:
            name: forgesync-tokens
            key: CODEBERG_TOKEN
```

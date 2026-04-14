# OTWLD Helm Charts

![OTWLD logo](./logo.png)

Helm charts for Kubernetes.

This repository backs [`https://helm.otwld.com`](https://helm.otwld.com) and publishes the Helm charts we maintain.

[Website](https://otwld.com) · [Discord](https://discord.otwld.com/) · [LinkedIn](https://linkedin.com/company/otwld)

## Quick Start

```bash
helm repo add otwld https://helm.otwld.com/
helm repo update
helm search repo otwld
```

Install a chart:

```bash
helm upgrade --install freqtrade otwld/freqtrade \
  --namespace freqtrade \
  --create-namespace
```

## Charts

| Chart | What It Is | Install | Source |
| --- | --- | --- | --- |
| `freqtrade` | Freqtrade for Kubernetes, built around a shared dashboard and isolated bot instances | `helm upgrade --install freqtrade otwld/freqtrade -n freqtrade --create-namespace` | [otwld/freqtrade-helm-chart](https://github.com/otwld/freqtrade-helm-chart) |
| `ollama` | Ollama on Kubernetes, with chart controls for storage, ingress, and runtime configuration | `helm upgrade --install ollama otwld/ollama -n ollama --create-namespace` | [otwld/ollama-helm](https://github.com/otwld/ollama-helm) |
| `velero-ui` | Velero UI for backup visibility and day-to-day cluster recovery operations | `helm upgrade --install velero-ui otwld/velero-ui -n velero-ui --create-namespace` | [otwld/velero-ui](https://github.com/otwld/velero-ui) |

## Registry Model

- This repository is the **distribution registry** for the charts we publish.
- Chart source code, examples, CI, and detailed documentation live in the linked source repositories.
- `helm.otwld.com` is the public install endpoint.

## Charts

### Freqtrade

Designed around:
- one shared `dashboard`
- many isolated `bots[]`
- per-bot config, secret, PVC, service, and optional ingress

Source:
- [github.com/otwld/freqtrade-helm-chart](https://github.com/otwld/freqtrade-helm-chart)

### Ollama

Kubernetes chart for serving Ollama with chart controls for persistence, GPUs, ingress, and runtime configuration.

Source:
- [github.com/otwld/ollama-helm](https://github.com/otwld/ollama-helm)

### Velero UI

Operational UI for Velero environments, packaged as a Helm chart for cluster deployment.

Source:
- [github.com/otwld/velero-ui](https://github.com/otwld/velero-ui)

## Common Commands

- List charts:

```bash
helm search repo otwld
```

- Inspect chart values:

```bash
helm show values otwld/freqtrade
helm show values otwld/ollama
helm show values otwld/velero-ui
```

- Pull a chart package locally:

```bash
helm pull otwld/freqtrade
```

## Notes

- This repo is intentionally minimal and registry-focused.
- If you want to contribute to a chart, use the chart’s source repository, not this registry repository.

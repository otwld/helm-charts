![otwld freqtrade helm chart banner](./banner.png)

# Freqtrade Helm Chart

![GitHub License](https://img.shields.io/github/license/otwld/freqtrade-helm-chart)
[![Helm Lint and Test](https://github.com/otwld/freqtrade-helm-chart/actions/workflows/ci.yaml/badge.svg?branch=main)](https://github.com/otwld/freqtrade-helm-chart/actions/workflows/ci.yaml)
[![Publish Chart](https://github.com/otwld/freqtrade-helm-chart/actions/workflows/cd.yaml/badge.svg?branch=main)](https://github.com/otwld/freqtrade-helm-chart/actions/workflows/cd.yaml)
[![Discord](https://img.shields.io/badge/Discord-OTWLD-blue?logo=discord&logoColor=white)](https://discord.gg/U24mpqTynB)

Production-grade Helm chart for running Freqtrade dashboards and multi-bot fleets on Kubernetes.

![Freqtrade Helm chart example deployment](./example.png)

## Why this chart

- Fleet-oriented model built around `dashboard` and `bots[]`
- Isolated StatefulSet, ConfigMap, Secret, PVC, Service, and optional Ingress per bot
- Shared analysis dashboard with optional companion data jobs for graphing
- Strategy delivery via image, PVC, or `initSync`
- Bots default to `initial_state: running` so dry-run and live bots start trading immediately unless you override that behavior
- Bot-level Telegram support aligned with the official Freqtrade configuration model
- Render-time validation for common Freqtrade configuration mistakes

## Architecture at a glance

| Component | Purpose | Workload | Storage | Exposure |
|-----------|---------|----------|---------|----------|
| `dashboard` | Shared FreqUI and analysis webserver | `StatefulSet` | Dedicated `user_data` PVC | Service + optional ingress |
| `bots[]` | One trading bot per strategy/runtime profile | `StatefulSet` | One `user_data` PVC per bot | Service + optional ingress |
| `dashboard.dataJobs` | Shared chart-data fetch for graph pages | `Job` or `CronJob` | Reuses dashboard PVC | Internal only |

## Install from OTWLD Helm Repo

```bash
helm repo add otwld https://helm.otwld.com/
helm repo update
helm upgrade --install freqtrade otwld/freqtrade \
  --namespace freqtrade \
  --create-namespace \
  -f values.yaml
```

## Local development quick start

```bash
helm lint .
./scripts/generate-docs.sh
./scripts/lint-examples.sh .

helm upgrade --install freqtrade . \
  --namespace freqtrade \
  --create-namespace \
  -f examples/minimal.yaml
```

## Example catalog

| File | Use case |
|------|----------|
| [`examples/minimal.yaml`](examples/minimal.yaml) | One bot, no ingress, API enabled |
| [`examples/bot-with-telegram.yaml`](examples/bot-with-telegram.yaml) | Bot-level Telegram integration |
| [`examples/dashboard-and-bots.yaml`](examples/dashboard-and-bots.yaml) | Shared dashboard plus multiple bots |
| [`examples/recommended-fleet.yaml`](examples/recommended-fleet.yaml) | Recommended production-style baseline with public dashboard and private bots |
| [`examples/private-bot-ui.yaml`](examples/private-bot-ui.yaml) | Bot UI enabled, no public ingress |
| [`examples/public-dashboard.yaml`](examples/public-dashboard.yaml) | Public dashboard with recurring data jobs |
| [`examples/external-secret.yaml`](examples/external-secret.yaml) | Private config sourced from External Secrets Operator |
| [`examples/existing-pvc.yaml`](examples/existing-pvc.yaml) | Reuse existing storage |
| [`examples/strategy-init-sync.yaml`](examples/strategy-init-sync.yaml) | Git-based strategy delivery |
| [`examples/values-freqtrade-v2.yaml`](examples/values-freqtrade-v2.yaml) | Large integration-style validation overlay |

## Operator docs

- [Home](docs/home.md)
- [Architecture](docs/architecture.md)
- [Installation and Upgrades](docs/installation_and_upgrades.md)
- [Examples](docs/examples.md)
- [Operations](docs/operations.md)
- [Releases and CI](docs/releases_and_ci.md)
- [Troubleshooting](docs/troubleshooting.md)

## Telegram

Telegram is configured per bot through `bots[].telegram`.

- Required when enabled: `token`, `chatId`
- Optional upstream-aligned fields: `topicId`, `authorizedUsers`, `allowCustomMessages`, `reload`, `balanceDustLevel`, `notificationSettings`, `keyboard`
- The chart renders Telegram as a dedicated secret-backed config overlay instead of mixing it into `config.public`

Reference:

- [Bot with Telegram example](examples/bot-with-telegram.yaml)
- https://www.freqtrade.io/en/stable/telegram-usage/
- https://www.freqtrade.io/en/stable/configuration/

## Values

This reference is generated from `values.yaml` with `helm-docs`.

Notes:

- `global` contains cross-cutting defaults shared by every workload
- `dashboard` models the optional analysis-first `freqtrade webserver`
- `bots` is an array. Since the default is `[]`, use the commented bot skeleton in `values.yaml` and the curated examples for the per-bot shape

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| bots | list | `[]` | Keep one bot per strategy/runtime profile for predictable upgrades and isolation. |
| dashboard | object | `{"affinity":{},"api":{"corsOrigins":[],"enabled":true,"port":8080},"args":[],"command":[],"config":{"existingSecret":"","existingSecretKey":"config-private.json","externalSecret":{"data":[],"dataFrom":[],"enabled":false,"refreshInterval":"1h","secretStoreRef":{"kind":"ClusterSecretStore","name":""},"target":{"creationPolicy":"Owner","name":""}},"public":{},"secret":{}},"containerSecurityContext":{},"dataJobs":{"downloadData":{"activeDeadlineSeconds":null,"backoffLimit":1,"days":14,"enabled":false,"erase":false,"extraArgs":[],"failedJobsHistoryLimit":1,"pairs":[],"resources":{"limits":{},"requests":{"cpu":"100m","memory":"256Mi"}},"schedule":"","successfulJobsHistoryLimit":1,"timeframes":["15m"],"ttlSecondsAfterFinished":86400},"enabled":false},"enabled":false,"env":[],"envFrom":[],"extraArgs":[],"extraContainers":[],"extraVolumeMounts":[],"extraVolumes":[],"image":{},"ingress":{"annotations":{},"className":"","enabled":false,"host":"","path":"/","pathType":"Prefix","tls":[]},"initContainers":[],"lifecycle":{},"networkPolicy":{},"nodeSelector":{},"persistence":{"accessModes":["ReadWriteOnce"],"annotations":{},"enabled":true,"existingClaim":"","mountPath":"/freqtrade/user_data","size":"20Gi","storageClassName":""},"podAnnotations":{},"podLabels":{},"podSecurityContext":{},"priorityClassName":"","probes":{},"resources":{},"service":{"annotations":{},"type":"ClusterIP"},"terminationGracePeriodSeconds":null,"tolerations":[],"topologySpreadConstraints":[],"ui":{"enabled":true}}` | Optional shared FreqUI / `freqtrade webserver` instance used for analysis and graphing. |
| dashboard.api.corsOrigins | list | `[]` | Explicit dashboard CORS origins. Bot API CORS defaults are managed separately. |
| dashboard.api.enabled | bool | `true` | Expose the dashboard REST API and FreqUI service. |
| dashboard.api.port | int | `8080` | Dashboard API service port. |
| dashboard.args | list | `[]` | Override the dashboard container args entirely. |
| dashboard.command | list | `[]` | Override the dashboard container command. |
| dashboard.config.existingSecret | string | `""` | Existing Secret name containing the private config file. |
| dashboard.config.existingSecretKey | string | `"config-private.json"` | Key inside `existingSecret` that contains the private config JSON. |
| dashboard.config.externalSecret | object | `{"data":[],"dataFrom":[],"enabled":false,"refreshInterval":"1h","secretStoreRef":{"kind":"ClusterSecretStore","name":""},"target":{"creationPolicy":"Owner","name":""}}` | External Secrets Operator settings for the private config file. |
| dashboard.config.public | object | `{}` | Public Freqtrade config rendered into `config.json`. |
| dashboard.config.secret | object | `{}` | Private Freqtrade config rendered into `config-private.json` when no external secret source is used. |
| dashboard.dataJobs.downloadData.activeDeadlineSeconds | string | `nil` | Optional Job deadline in seconds. |
| dashboard.dataJobs.downloadData.backoffLimit | int | `1` | Maximum retries for the Job. |
| dashboard.dataJobs.downloadData.days | int | `14` | Number of historical days to download. |
| dashboard.dataJobs.downloadData.enabled | bool | `false` | Enable the `download-data` companion workload. |
| dashboard.dataJobs.downloadData.erase | bool | `false` | Erase existing data before downloading. |
| dashboard.dataJobs.downloadData.extraArgs | list | `[]` | Extra CLI args appended to `freqtrade download-data`. |
| dashboard.dataJobs.downloadData.failedJobsHistoryLimit | int | `1` | Failed CronJob history retained by Kubernetes. |
| dashboard.dataJobs.downloadData.pairs | list | `[]` | Pair list used by the data job. Required when enabled. |
| dashboard.dataJobs.downloadData.resources | object | `{"limits":{},"requests":{"cpu":"100m","memory":"256Mi"}}` | Resources for the data job container. |
| dashboard.dataJobs.downloadData.schedule | string | `""` | Cron schedule for recurring downloads. Leave empty to render a one-shot Job. |
| dashboard.dataJobs.downloadData.successfulJobsHistoryLimit | int | `1` | Successful CronJob history retained by Kubernetes. |
| dashboard.dataJobs.downloadData.timeframes | list | `["15m"]` | Timeframes fetched by the data job. Required when enabled. |
| dashboard.dataJobs.downloadData.ttlSecondsAfterFinished | int | `86400` | TTL in seconds for completed one-shot Jobs. |
| dashboard.dataJobs.enabled | bool | `false` | Enable dashboard-owned data jobs such as `download-data`. |
| dashboard.enabled | bool | `false` | Enable the shared dashboard StatefulSet. |
| dashboard.extraArgs | list | `[]` | Extra args appended to the chart-generated Freqtrade command. |
| dashboard.image | object | `{}` | Override the default image for the dashboard only. |
| dashboard.ingress.annotations | object | `{}` | Extra annotations for the dashboard ingress. |
| dashboard.ingress.className | string | `""` | IngressClass name for the dashboard ingress. |
| dashboard.ingress.enabled | bool | `false` | Enable ingress for the dashboard UI/API. |
| dashboard.ingress.host | string | `""` | Dashboard ingress host. |
| dashboard.ingress.path | string | `"/"` | Dashboard ingress path. |
| dashboard.ingress.pathType | string | `"Prefix"` | Dashboard ingress pathType. |
| dashboard.ingress.tls | list | `[]` | Optional dashboard ingress TLS entries. |
| dashboard.persistence.accessModes | list | `["ReadWriteOnce"]` | PVC access modes. |
| dashboard.persistence.annotations | object | `{}` | Extra annotations for the dashboard PVC. |
| dashboard.persistence.enabled | bool | `true` | Enable persistent storage for the dashboard `user_data` directory. |
| dashboard.persistence.existingClaim | string | `""` | Reuse an existing claim instead of creating one. |
| dashboard.persistence.mountPath | string | `"/freqtrade/user_data"` | Mount path for dashboard `user_data`. |
| dashboard.persistence.size | string | `"20Gi"` | PVC size when the chart creates the claim. |
| dashboard.persistence.storageClassName | string | `""` | StorageClass for the dashboard PVC. Empty uses the cluster default. |
| dashboard.resources | object | `{}` | Optional per-dashboard overrides for global defaults. |
| dashboard.service.annotations | object | `{}` | Extra annotations for the dashboard Service. |
| dashboard.service.type | string | `"ClusterIP"` | Kubernetes Service type for the dashboard API/UI. |
| dashboard.ui.enabled | bool | `true` | Enable the dashboard FreqUI surface. Dashboard mode requires this to stay true. |
| global | object | `{"affinity":{},"containerSecurityContext":{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"runAsGroup":1000,"runAsNonRoot":true,"runAsUser":1000,"seccompProfile":{"type":"RuntimeDefault"}},"env":[],"envFrom":[],"extraContainers":[],"extraVolumeMounts":[],"extraVolumes":[],"fullnameOverride":"","image":{"pullPolicy":"IfNotPresent","pullSecrets":[],"repository":"freqtradeorg/freqtrade","tag":"stable"},"initContainers":[],"lifecycle":{},"nameOverride":"","networkPolicy":{"egress":{"allowDns":true,"rules":[]},"enabled":false,"ingress":{"from":[]}},"nodeSelector":{},"podAnnotations":{},"podLabels":{},"podSecurityContext":{"fsGroup":1000,"fsGroupChangePolicy":"OnRootMismatch"},"priorityClassName":"","probes":{"liveness":{"enabled":true,"failureThreshold":6,"initialDelaySeconds":30,"periodSeconds":15,"timeoutSeconds":5},"readiness":{"enabled":true,"failureThreshold":6,"initialDelaySeconds":5,"periodSeconds":10,"successThreshold":1,"timeoutSeconds":5},"startup":{"enabled":true,"failureThreshold":30,"initialDelaySeconds":10,"periodSeconds":10,"timeoutSeconds":5}},"resources":{"limits":{},"requests":{"cpu":"250m","memory":"512Mi"}},"serviceAccount":{"annotations":{},"automountToken":false,"create":false,"name":""},"terminationGracePeriodSeconds":60,"tolerations":[],"topologySpreadConstraints":[]}` | Shared defaults applied to the dashboard and every bot unless overridden. |
| global.affinity | object | `{}` | Shared affinity applied to dashboard and bots. |
| global.containerSecurityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"runAsGroup":1000,"runAsNonRoot":true,"runAsUser":1000,"seccompProfile":{"type":"RuntimeDefault"}}` | Container-level security context defaults. |
| global.env | list | `[]` | Shared environment variables injected into every main container. |
| global.envFrom | list | `[]` | Shared envFrom entries injected into every main container. |
| global.extraContainers | list | `[]` | Shared sidecars or extra containers appended after the main Freqtrade container. |
| global.extraVolumeMounts | list | `[]` | Shared extra volumeMounts for the main Freqtrade container. |
| global.extraVolumes | list | `[]` | Shared extra volumes mounted into dashboard and bot pods. |
| global.fullnameOverride | string | `""` | Override the full release name for generated resource names. |
| global.image | object | `{"pullPolicy":"IfNotPresent","pullSecrets":[],"repository":"freqtradeorg/freqtrade","tag":"stable"}` | Default image settings for dashboard and bot workloads. |
| global.image.pullPolicy | string | `"IfNotPresent"` | Image pull policy for the main container. |
| global.image.pullSecrets | list | `[]` | Optional image pull secrets for private registries. |
| global.image.repository | string | `"freqtradeorg/freqtrade"` | Freqtrade image repository. |
| global.image.tag | string | `"stable"` | Freqtrade image tag. |
| global.initContainers | list | `[]` | Shared init containers appended after chart-managed init containers. |
| global.lifecycle | object | `{}` | Default container lifecycle hooks. |
| global.nameOverride | string | `""` | Override `Chart.yaml.name` for generated resource names. |
| global.networkPolicy | object | `{"egress":{"allowDns":true,"rules":[]},"enabled":false,"ingress":{"from":[]}}` | Shared NetworkPolicy defaults for dashboard and bots. |
| global.networkPolicy.egress.allowDns | bool | `true` | Allow DNS egress automatically. |
| global.networkPolicy.egress.rules | list | `[]` | Additional egress rules appended after DNS. |
| global.networkPolicy.enabled | bool | `false` | Enable per-instance NetworkPolicy resources. |
| global.networkPolicy.ingress.from | list | `[]` | Additional ingress `from` selectors allowed to reach the API port. |
| global.nodeSelector | object | `{}` | Shared nodeSelector applied to dashboard and bots. |
| global.podAnnotations | object | `{}` | Shared pod annotations merged into each dashboard and bot pod. |
| global.podLabels | object | `{}` | Shared pod labels merged into each dashboard and bot pod. |
| global.podSecurityContext | object | `{"fsGroup":1000,"fsGroupChangePolicy":"OnRootMismatch"}` | Pod-level security context defaults. |
| global.podSecurityContext.fsGroup | int | `1000` | File system group used for mounted volumes. |
| global.podSecurityContext.fsGroupChangePolicy | string | `"OnRootMismatch"` | Change file ownership only when needed. |
| global.priorityClassName | string | `""` | Shared PriorityClass for dashboard and bots. |
| global.probes | object | `{"liveness":{"enabled":true,"failureThreshold":6,"initialDelaySeconds":30,"periodSeconds":15,"timeoutSeconds":5},"readiness":{"enabled":true,"failureThreshold":6,"initialDelaySeconds":5,"periodSeconds":10,"successThreshold":1,"timeoutSeconds":5},"startup":{"enabled":true,"failureThreshold":30,"initialDelaySeconds":10,"periodSeconds":10,"timeoutSeconds":5}}` | Probe defaults for dashboard and bot StatefulSets. |
| global.resources | object | `{"limits":{},"requests":{"cpu":"250m","memory":"512Mi"}}` | Default container resources for dashboard and bots. |
| global.serviceAccount | object | `{"annotations":{},"automountToken":false,"create":false,"name":""}` | Shared ServiceAccount settings for all workloads in the release. |
| global.serviceAccount.annotations | object | `{}` | Extra annotations for the shared ServiceAccount. |
| global.serviceAccount.automountToken | bool | `false` | Mount the Kubernetes API token into pods. |
| global.serviceAccount.create | bool | `false` | Create a dedicated ServiceAccount for the release. |
| global.serviceAccount.name | string | `""` | Use an existing ServiceAccount name. When empty, the chart uses `default` unless `create=true`. |
| global.terminationGracePeriodSeconds | int | `60` | Default graceful shutdown window in seconds. |
| global.tolerations | list | `[]` | Shared tolerations applied to dashboard and bots. |
| global.topologySpreadConstraints | list | `[]` | Shared topology spread constraints applied to dashboard and bots. |

## Source Code

* <https://github.com/otwld/freqtrade-helm-chart>
* <https://github.com/freqtrade/freqtrade>

## Release workflow

- `./scripts/generate-docs.sh` refreshes `README.md` from `README.md.gotmpl` and `values.yaml`
- `./scripts/lint-examples.sh .` validates the chart and every shipped example
- `.github/workflows/ci.yaml` enforces docs freshness and packages the chart on every PR and `main` push
- `.github/workflows/release-readiness.yaml` validates tagged builds and uploads the packaged chart artifact
- `.github/workflows/cd.yaml` publishes tagged releases to GitHub releases and mirrors the chart sources into the central `helm-charts` repository used by `https://helm.otwld.com/`

## Support

- For questions, suggestions, and discussion about this chart please visit [Freqtrade-Helm issue page](https://github.com/otwld/freqtrade-helm-chart/issues) or join our [OTWLD Discord](https://discord.gg/U24mpqTynB)

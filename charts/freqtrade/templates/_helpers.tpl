{{/*
Expand the chart name.
*/}}
{{- define "freqtrade.name" -}}
{{- default .Chart.Name .Values.global.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "freqtrade.fullname" -}}
{{- if .Values.global.fullnameOverride -}}
{{- .Values.global.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := include "freqtrade.name" . -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Chart label.
*/}}
{{- define "freqtrade.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels.
*/}}
{{- define "freqtrade.commonLabels" -}}
helm.sh/chart: {{ include "freqtrade.chart" .root }}
app.kubernetes.io/name: {{ include "freqtrade.name" .root }}
app.kubernetes.io/instance: {{ .root.Release.Name }}
app.kubernetes.io/version: {{ .root.Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .root.Release.Service }}
freqtrade.io/component: {{ .instance._component }}
freqtrade.io/name: {{ .instance._name }}
{{- end -}}

{{/*
Selector labels.
*/}}
{{- define "freqtrade.selectorLabels" -}}
app.kubernetes.io/name: {{ include "freqtrade.name" .root }}
app.kubernetes.io/instance: {{ .root.Release.Name }}
freqtrade.io/component: {{ .instance._component }}
freqtrade.io/name: {{ .instance._name }}
{{- end -}}

{{/*
Service account name.
*/}}
{{- define "freqtrade.serviceAccountName" -}}
{{- if .Values.global.serviceAccount.create -}}
{{- default (include "freqtrade.fullname" .) .Values.global.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.global.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{/*
Base defaults applied to every instance.
*/}}
{{- define "freqtrade.instance.baseDefaults" -}}
enabled: true
mode: dryRun
image: {}
command: []
args: []
extraArgs: []
api:
  enabled: true
  port: 8080
  corsOrigins: []
ui:
  enabled: false
service:
  type: ClusterIP
  annotations: {}
ingress:
  enabled: false
  className: ""
  annotations: {}
  host: ""
  path: /
  pathType: Prefix
  tls: []
strategy:
  name: ""
  source:
    type: image
    path: ""
    volume:
      existingClaim: ""
      mountPath: ""
      accessModes:
        - ReadWriteOnce
      size: 5Gi
      storageClassName: ""
      annotations: {}
    initSync:
      enabled: false
      image:
        repository: alpine/git
        tag: "2.47.2"
        pullPolicy: IfNotPresent
        pullSecrets: []
      command: []
      env: []
      envFrom: []
telegram:
  enabled: false
  token: ""
  chatId: ""
  topicId: ""
  authorizedUsers: []
  allowCustomMessages: null
  reload: null
  balanceDustLevel: null
  notificationSettings: {}
  keyboard: []
config:
  public: {}
  secret: {}
  existingSecret: ""
  existingSecretKey: config-private.json
  externalSecret:
    enabled: false
    refreshInterval: 1h
    secretStoreRef:
      name: ""
      kind: ClusterSecretStore
    target:
      name: ""
      creationPolicy: Owner
    data: []
    dataFrom: []
persistence:
  enabled: true
  mountPath: /freqtrade/user_data
  existingClaim: ""
  accessModes:
    - ReadWriteOnce
  size: 20Gi
  storageClassName: ""
  annotations: {}
resources: {}
podSecurityContext: {}
containerSecurityContext: {}
podAnnotations: {}
podLabels: {}
env: []
envFrom: []
initContainers: []
extraContainers: []
extraVolumes: []
extraVolumeMounts: []
nodeSelector: {}
affinity: {}
tolerations: []
topologySpreadConstraints: []
priorityClassName: ""
terminationGracePeriodSeconds: null
lifecycle: {}
probes: {}
networkPolicy: {}
{{- end -}}

{{/*
Normalize the dashboard values.
*/}}
{{- define "freqtrade.normalizeDashboard" -}}
{{- $root := .root -}}
{{- $base := fromYaml (include "freqtrade.instance.baseDefaults" $root) -}}
{{- $defaults := dict "enabled" false "mode" "webserver" "ui" (dict "enabled" true) "api" (dict "enabled" true "port" 8080 "corsOrigins" (list)) -}}
{{- $instance := mergeOverwrite (deepCopy $base) $defaults -}}
{{- $instance = mergeOverwrite $instance (.dashboard | default dict) -}}
{{- $_ := set $instance "_component" "dashboard" -}}
{{- $_ := set $instance "_name" "dashboard" -}}
{{- toYaml $instance -}}
{{- end -}}

{{/*
Normalize a bot definition.
*/}}
{{- define "freqtrade.normalizeBot" -}}
{{- $root := .root -}}
{{- $base := fromYaml (include "freqtrade.instance.baseDefaults" $root) -}}
{{- $instance := mergeOverwrite (deepCopy $base) (.bot | default dict) -}}
{{- $_ := set $instance "_component" "bot" -}}
{{- $_ := set $instance "_name" (required "bots[].name is required" $instance.name) -}}
{{- toYaml $instance -}}
{{- end -}}

{{/*
Instance fullname.
*/}}
{{- define "freqtrade.instance.fullname" -}}
{{- $name := "" -}}
{{- if eq .instance._component "dashboard" -}}
{{- $name = printf "%s-dashboard" (include "freqtrade.fullname" .root) -}}
{{- else -}}
{{- $name = printf "%s-bot-%s" (include "freqtrade.fullname" .root) .instance._name -}}
{{- end -}}
{{- $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Instance service names.
*/}}
{{- define "freqtrade.instance.headlessServiceName" -}}
{{- printf "%s-headless" (include "freqtrade.instance.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "freqtrade.instance.apiServiceName" -}}
{{- include "freqtrade.instance.fullname" . -}}
{{- end -}}

{{/*
Config resource names.
*/}}
{{- define "freqtrade.instance.publicConfigName" -}}
{{- printf "%s-config" (include "freqtrade.instance.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "freqtrade.instance.generatedPrivateConfigSecretName" -}}
{{- printf "%s-private-config" (include "freqtrade.instance.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "freqtrade.instance.privateConfigSecretName" -}}
{{- if .instance.config.existingSecret -}}
{{- .instance.config.existingSecret -}}
{{- else if and .instance.config.externalSecret.enabled .instance.config.externalSecret.target.name -}}
{{- .instance.config.externalSecret.target.name -}}
{{- else -}}
{{- include "freqtrade.instance.generatedPrivateConfigSecretName" . -}}
{{- end -}}
{{- end -}}

{{- define "freqtrade.instance.privateConfigEnabled" -}}
{{- if or .instance.config.existingSecret .instance.config.externalSecret.enabled (not (empty (.instance.config.secret | default dict))) -}}true{{- else -}}false{{- end -}}
{{- end -}}

{{/*
Telegram config resource names.
*/}}
{{- define "freqtrade.instance.telegramEnabled" -}}
{{- $telegram := .instance.telegram | default dict -}}
{{- if and (eq .instance._component "bot") ($telegram.enabled | default false) -}}true{{- else -}}false{{- end -}}
{{- end -}}

{{- define "freqtrade.instance.telegramSecretName" -}}
{{- printf "%s-telegram-config" (include "freqtrade.instance.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
PVC names.
*/}}
{{- define "freqtrade.instance.userDataClaimName" -}}
{{- if .instance.persistence.existingClaim -}}
{{- .instance.persistence.existingClaim -}}
{{- else -}}
{{- printf "%s-user-data" (include "freqtrade.instance.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "freqtrade.instance.strategyClaimName" -}}
{{- if .instance.strategy.source.volume.existingClaim -}}
{{- .instance.strategy.source.volume.existingClaim -}}
{{- else -}}
{{- printf "%s-strategies" (include "freqtrade.instance.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Whether the instance requires a strategy.
*/}}
{{- define "freqtrade.instance.requiresStrategy" -}}
{{- if eq .instance._component "bot" -}}true{{- else -}}false{{- end -}}
{{- end -}}

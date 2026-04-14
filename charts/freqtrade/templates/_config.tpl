{{/*
Telegram config rendered as a dedicated secret-backed overlay file.
*/}}
{{- define "freqtrade.instance.telegramConfig" -}}
{{- $telegramValues := .instance.telegram | default dict -}}
{{- $telegram := dict "enabled" true "token" $telegramValues.token "chat_id" $telegramValues.chatId -}}
{{- if $telegramValues.topicId -}}
  {{- $_ := set $telegram "topic_id" $telegramValues.topicId -}}
{{- end -}}
{{- if $telegramValues.authorizedUsers -}}
  {{- $_ := set $telegram "authorized_users" $telegramValues.authorizedUsers -}}
{{- end -}}
{{- if hasKey $telegramValues "allowCustomMessages" -}}
  {{- $_ := set $telegram "allow_custom_messages" $telegramValues.allowCustomMessages -}}
{{- end -}}
{{- if hasKey $telegramValues "reload" -}}
  {{- $_ := set $telegram "reload" $telegramValues.reload -}}
{{- end -}}
{{- if hasKey $telegramValues "balanceDustLevel" -}}
  {{- $_ := set $telegram "balance_dust_level" $telegramValues.balanceDustLevel -}}
{{- end -}}
{{- if $telegramValues.notificationSettings -}}
  {{- $_ := set $telegram "notification_settings" $telegramValues.notificationSettings -}}
{{- end -}}
{{- if $telegramValues.keyboard -}}
  {{- $_ := set $telegram "keyboard" $telegramValues.keyboard -}}
{{- end -}}
{{- dict "telegram" $telegram | toYaml -}}
{{- end -}}

{{/*
Resolve strategy path.
*/}}
{{- define "freqtrade.instance.strategyPath" -}}
{{- if .instance.strategy.source.path -}}
{{- .instance.strategy.source.path -}}
{{- else if and (eq .instance.strategy.source.type "volume") .instance.strategy.source.volume.mountPath -}}
{{- .instance.strategy.source.volume.mountPath -}}
{{- else -}}
{{- printf "%s/strategies" .instance.persistence.mountPath -}}
{{- end -}}
{{- end -}}

{{/*
Resolve mode command.
*/}}
{{- define "freqtrade.instance.modeCommand" -}}
{{- if eq .instance.mode "webserver" -}}webserver{{- else -}}trade{{- end -}}
{{- end -}}

{{/*
Resolve effective bot API CORS origins.
*/}}
{{- define "freqtrade.instance.effectiveCorsOrigins" -}}
{{- $origins := .instance.api.corsOrigins | default list -}}
{{- if not (empty $origins) -}}
{{- toYaml $origins -}}
{{- else if and (eq .instance._component "bot") .root.Values.dashboard.enabled .root.Values.dashboard.ingress.enabled .root.Values.dashboard.ingress.host -}}
{{- $host := .root.Values.dashboard.ingress.host -}}
{{- toYaml (list (printf "https://%s" $host) (printf "http://%s" $host)) -}}
{{- else -}}
{{- toYaml (list) -}}
{{- end -}}
{{- end -}}

{{/*
Effective public config with chart-owned defaults injected.
*/}}
{{- define "freqtrade.instance.effectivePublicConfig" -}}
{{- $config := deepCopy (.instance.config.public | default dict) -}}
{{- if eq .instance._component "bot" -}}
  {{- if not (hasKey $config "dry_run") -}}
    {{- $_ := set $config "dry_run" (eq .instance.mode "dryRun") -}}
  {{- end -}}
  {{- if not (hasKey $config "initial_state") -}}
    {{- $_ := set $config "initial_state" "running" -}}
  {{- end -}}
{{- end -}}
{{- if or .instance.api.enabled .instance.ui.enabled (eq .instance._component "dashboard") -}}
  {{- $apiServer := deepCopy ((get $config "api_server") | default dict) -}}
  {{- $corsOrigins := include "freqtrade.instance.effectiveCorsOrigins" . | fromYamlArray -}}
  {{- $_ := set $apiServer "enabled" true -}}
  {{- if not (hasKey $apiServer "listen_ip_address") -}}
    {{- $_ := set $apiServer "listen_ip_address" "0.0.0.0" -}}
  {{- end -}}
  {{- if not (hasKey $apiServer "listen_port") -}}
    {{- $_ := set $apiServer "listen_port" .instance.api.port -}}
  {{- end -}}
  {{- if not (empty $corsOrigins) -}}
    {{- $_ := set $apiServer "CORS_origins" $corsOrigins -}}
  {{- end -}}
  {{- $_ := set $config "api_server" $apiServer -}}
{{- end -}}
{{- toYaml $config -}}
{{- end -}}

{{/*
Container args.
*/}}
{{- define "freqtrade.instance.containerArgs" -}}
- {{ include "freqtrade.instance.modeCommand" . | quote }}
- --config
- /etc/freqtrade/config.json
{{- if eq (include "freqtrade.instance.privateConfigEnabled" .) "true" }}
- --config
- /etc/freqtrade/config-private.json
{{- end }}
{{- if eq (include "freqtrade.instance.telegramEnabled" .) "true" }}
- --config
- /etc/freqtrade/config-telegram.json
{{- end }}
{{- if eq (include "freqtrade.instance.requiresStrategy" .) "true" }}
- --strategy
- {{ required (printf "strategy.name is required for bot %s" .instance._name) .instance.strategy.name | quote }}
- --strategy-path
- {{ include "freqtrade.instance.strategyPath" . | quote }}
{{- end }}
{{- range (.instance.extraArgs | default list) }}
- {{ . | quote }}
{{- end }}
{{- end -}}

{{/*
Merged pod annotations with rollout checksums.
*/}}
{{- define "freqtrade.instance.podAnnotations" -}}
{{- $annotations := mergeOverwrite (deepCopy (.root.Values.global.podAnnotations | default dict)) (.instance.podAnnotations | default dict) -}}
{{- $_ := set $annotations "checksum/public-config" (include "freqtrade.instance.effectivePublicConfig" . | sha256sum) -}}
{{- if .instance.config.existingSecret -}}
  {{- $_ := set $annotations "checksum/private-config" (.instance.config.existingSecret | sha256sum) -}}
{{- else if .instance.config.externalSecret.enabled -}}
  {{- $_ := set $annotations "checksum/private-config" (include "freqtrade.instance.privateConfigSecretName" . | sha256sum) -}}
{{- else -}}
  {{- $_ := set $annotations "checksum/private-config" ((toYaml (.instance.config.secret | default dict)) | sha256sum) -}}
{{- end -}}
{{- if eq (include "freqtrade.instance.telegramEnabled" .) "true" -}}
  {{- $_ := set $annotations "checksum/telegram-config" (include "freqtrade.instance.telegramConfig" . | sha256sum) -}}
{{- end -}}
{{- if eq .instance.strategy.source.type "initSync" -}}
  {{- $_ := set $annotations "checksum/strategy-sync" ((toYaml .instance.strategy.source.initSync) | sha256sum) -}}
{{- end -}}
{{- toYaml $annotations -}}
{{- end -}}

{{/*
Render the strategy init container when enabled.
*/}}
{{- define "freqtrade.instance.strategyInitContainer" -}}
{{- if and (eq .instance.strategy.source.type "initSync") .instance.strategy.source.initSync.enabled -}}
{{- $image := mergeOverwrite (deepCopy (.root.Values.global.image | default dict)) (.instance.strategy.source.initSync.image | default dict) -}}
- name: strategy-sync
  image: "{{ $image.repository }}:{{ $image.tag }}"
  imagePullPolicy: {{ $image.pullPolicy }}
  {{- with .instance.strategy.source.initSync.command }}
  command:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with .instance.strategy.source.initSync.envFrom }}
  envFrom:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with .instance.strategy.source.initSync.env }}
  env:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  volumeMounts:
    - name: user-data
      mountPath: {{ .instance.persistence.mountPath }}
{{- end -}}
{{- end -}}

{{/*
Main container volume mounts.
*/}}
{{- define "freqtrade.instance.volumeMounts" -}}
- name: public-config
  mountPath: /etc/freqtrade/config.json
  subPath: config.json
  readOnly: true
{{- if eq (include "freqtrade.instance.privateConfigEnabled" .) "true" }}
- name: private-config
  mountPath: /etc/freqtrade/config-private.json
  subPath: {{ default "config-private.json" .instance.config.existingSecretKey }}
  readOnly: true
{{- end }}
{{- if eq (include "freqtrade.instance.telegramEnabled" .) "true" }}
- name: telegram-config
  mountPath: /etc/freqtrade/config-telegram.json
  subPath: config-telegram.json
  readOnly: true
{{- end }}
- name: user-data
  mountPath: {{ .instance.persistence.mountPath }}
{{- if eq .instance.strategy.source.type "volume" }}
- name: strategy-volume
  mountPath: {{ include "freqtrade.instance.strategyPath" . }}
{{- end }}
{{- with .instance.extraVolumeMounts }}
{{ toYaml . }}
{{- end }}
{{- end -}}

{{/*
Pod volumes.
*/}}
{{- define "freqtrade.instance.volumes" -}}
- name: public-config
  configMap:
    name: {{ include "freqtrade.instance.publicConfigName" . }}
{{- if eq (include "freqtrade.instance.privateConfigEnabled" .) "true" }}
- name: private-config
  secret:
    secretName: {{ include "freqtrade.instance.privateConfigSecretName" . }}
{{- end }}
{{- if eq (include "freqtrade.instance.telegramEnabled" .) "true" }}
- name: telegram-config
  secret:
    secretName: {{ include "freqtrade.instance.telegramSecretName" . }}
{{- end }}
- name: user-data
  {{- if .instance.persistence.enabled }}
  persistentVolumeClaim:
    claimName: {{ include "freqtrade.instance.userDataClaimName" . }}
  {{- else }}
  emptyDir: {}
  {{- end }}
{{- if eq .instance.strategy.source.type "volume" }}
- name: strategy-volume
  persistentVolumeClaim:
    claimName: {{ include "freqtrade.instance.strategyClaimName" . }}
{{- end }}
{{- with .instance.extraVolumes }}
{{ toYaml . }}
{{- end }}
{{- end -}}

{{/*
Stateful probes.
*/}}
{{- define "freqtrade.instance.statefulProbes" -}}
{{- $probes := mergeOverwrite (deepCopy (.root.Values.global.probes | default dict)) (.instance.probes | default dict) -}}
{{- $httpProbe := dict "httpGet" (dict "path" "/api/v1/ping" "port" "http") -}}
{{- $execProbe := dict "exec" (dict "command" (list "/bin/sh" "-ec" "pgrep -f 'freqtrade' >/dev/null")) -}}
{{- $probeAction := ternary $httpProbe $execProbe .instance.api.enabled -}}
{{- if ($probes.startup.enabled | default false) }}
startupProbe:
  {{- toYaml $probeAction | nindent 2 }}
  initialDelaySeconds: {{ $probes.startup.initialDelaySeconds | default 10 }}
  periodSeconds: {{ $probes.startup.periodSeconds | default 10 }}
  timeoutSeconds: {{ $probes.startup.timeoutSeconds | default 5 }}
  failureThreshold: {{ $probes.startup.failureThreshold | default 30 }}
{{- end }}
{{- if ($probes.readiness.enabled | default false) }}
readinessProbe:
  {{- toYaml $probeAction | nindent 2 }}
  initialDelaySeconds: {{ $probes.readiness.initialDelaySeconds | default 5 }}
  periodSeconds: {{ $probes.readiness.periodSeconds | default 10 }}
  timeoutSeconds: {{ $probes.readiness.timeoutSeconds | default 5 }}
  failureThreshold: {{ $probes.readiness.failureThreshold | default 6 }}
  successThreshold: {{ $probes.readiness.successThreshold | default 1 }}
{{- end }}
{{- if ($probes.liveness.enabled | default false) }}
livenessProbe:
  {{- toYaml $probeAction | nindent 2 }}
  initialDelaySeconds: {{ $probes.liveness.initialDelaySeconds | default 30 }}
  periodSeconds: {{ $probes.liveness.periodSeconds | default 15 }}
  timeoutSeconds: {{ $probes.liveness.timeoutSeconds | default 5 }}
  failureThreshold: {{ $probes.liveness.failureThreshold | default 6 }}
{{- end }}
{{- end -}}

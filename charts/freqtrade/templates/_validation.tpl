{{/*
Validate one normalized instance.
*/}}
{{- define "freqtrade.instance.validate" -}}
{{- $instance := .instance -}}
{{- $privateConfigRef := or $instance.config.existingSecret $instance.config.externalSecret.enabled -}}
{{- $public := $instance.config.public | default dict -}}
{{- $private := $instance.config.secret | default dict -}}
{{- $exchange := (get $public "exchange") | default dict -}}
{{- $pairlists := (get $public "pairlists") | default list -}}
{{- $secretApi := (get $private "api_server") | default dict -}}
{{- $telegram := $instance.telegram | default dict -}}
{{- if and $instance.config.existingSecret $instance.config.externalSecret.enabled -}}
{{- fail (printf "%s: config.existingSecret and config.externalSecret.enabled are mutually exclusive" $instance._name) -}}
{{- end -}}
{{- if eq $instance._component "dashboard" -}}
  {{- if ne $instance.mode "webserver" -}}
    {{- fail "dashboard.mode must be webserver" -}}
  {{- end -}}
  {{- if not $instance.ui.enabled -}}
    {{- fail "dashboard.ui.enabled must be true when dashboard.enabled=true" -}}
  {{- end -}}
  {{- if not $instance.api.enabled -}}
    {{- fail "dashboard.api.enabled must be true when dashboard.enabled=true" -}}
  {{- end -}}
  {{- if ($telegram.enabled | default false) -}}
    {{- fail "dashboard.telegram.enabled is not supported; configure Telegram on bots only" -}}
  {{- end -}}
{{- else -}}
  {{- if and (ne $instance.mode "trade") (ne $instance.mode "dryRun") -}}
    {{- fail (printf "bot %s: mode must be trade or dryRun" $instance._name) -}}
  {{- end -}}
  {{- if not $instance.strategy.name -}}
    {{- fail (printf "bot %s: strategy.name is required" $instance._name) -}}
  {{- end -}}
  {{- if ($telegram.enabled | default false) -}}
    {{- if hasKey $public "telegram" -}}
      {{- fail (printf "bot %s: telegram.enabled cannot be combined with config.public.telegram" $instance._name) -}}
    {{- end -}}
    {{- if hasKey $private "telegram" -}}
      {{- fail (printf "bot %s: telegram.enabled cannot be combined with config.secret.telegram" $instance._name) -}}
    {{- end -}}
    {{- if not $telegram.token -}}
      {{- fail (printf "bot %s: telegram.token is required when telegram.enabled=true" $instance._name) -}}
    {{- end -}}
    {{- if not $telegram.chatId -}}
      {{- fail (printf "bot %s: telegram.chatId is required when telegram.enabled=true" $instance._name) -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- if and $instance.ui.enabled (not $instance.api.enabled) -}}
{{- fail (printf "%s: ui.enabled requires api.enabled=true" $instance._name) -}}
{{- end -}}
{{- if and $instance.ingress.enabled (not $instance.ui.enabled) -}}
{{- fail (printf "%s: ingress.enabled requires ui.enabled=true" $instance._name) -}}
{{- end -}}
{{- if and $instance.ingress.enabled (not $instance.api.enabled) -}}
{{- fail (printf "%s: ingress.enabled requires api.enabled=true" $instance._name) -}}
{{- end -}}
{{- if and $instance.ingress.enabled (not $instance.ingress.host) -}}
{{- fail (printf "%s: ingress.host is required when ingress.enabled=true" $instance._name) -}}
{{- end -}}
{{- $effectiveCorsOrigins := include "freqtrade.instance.effectiveCorsOrigins" . | fromYamlArray -}}
{{- range $origin := ($effectiveCorsOrigins | default list) }}
  {{- if hasSuffix "/" $origin -}}
    {{- fail (printf "%s: api.corsOrigins entries must not end with '/': %s" $instance._name $origin) -}}
  {{- end -}}
{{- end -}}
{{- if eq $instance.strategy.source.type "initSync" -}}
  {{- if not $instance.strategy.source.initSync.enabled -}}
    {{- fail (printf "bot %s: strategy.source.initSync.enabled must be true when strategy.source.type=initSync" $instance._name) -}}
  {{- end -}}
  {{- if empty ($instance.strategy.source.initSync.command | default list) -}}
    {{- fail (printf "bot %s: strategy.source.initSync.command is required when using initSync" $instance._name) -}}
  {{- end -}}
{{- end -}}
{{- if and (not $privateConfigRef) (or $instance.api.enabled $instance.ui.enabled (eq $instance._component "dashboard")) -}}
  {{- if not (get $secretApi "username") -}}
    {{- fail (printf "%s: config.secret.api_server.username is required when api.enabled=true" $instance._name) -}}
  {{- end -}}
  {{- if not (get $secretApi "password") -}}
    {{- fail (printf "%s: config.secret.api_server.password is required when api.enabled=true" $instance._name) -}}
  {{- end -}}
  {{- if not (get $secretApi "jwt_secret_key") -}}
    {{- fail (printf "%s: config.secret.api_server.jwt_secret_key is required when api.enabled=true" $instance._name) -}}
  {{- end -}}
  {{- if not (get $secretApi "ws_token") -}}
    {{- fail (printf "%s: config.secret.api_server.ws_token is required when api.enabled=true" $instance._name) -}}
  {{- end -}}
{{- end -}}
{{- if not (get $exchange "name") -}}
  {{- fail (printf "%s: config.public.exchange.name is required" $instance._name) -}}
{{- end -}}
{{- if not (get $public "stake_currency") -}}
  {{- fail (printf "%s: config.public.stake_currency is required" $instance._name) -}}
{{- end -}}
{{- if not (hasKey $public "stake_amount") -}}
  {{- fail (printf "%s: config.public.stake_amount is required" $instance._name) -}}
{{- end -}}
{{- if not (get $public "timeframe") -}}
  {{- fail (printf "%s: config.public.timeframe is required" $instance._name) -}}
{{- end -}}
{{- if ne $instance._component "dashboard" -}}
  {{- if not (get $public "entry_pricing") -}}
    {{- fail (printf "%s: config.public.entry_pricing is required" $instance._name) -}}
  {{- end -}}
  {{- if not (get $public "exit_pricing") -}}
    {{- fail (printf "%s: config.public.exit_pricing is required" $instance._name) -}}
  {{- end -}}
{{- end -}}
{{- if empty $pairlists -}}
  {{- fail (printf "%s: config.public.pairlists is required" $instance._name) -}}
{{- end -}}
{{- range $pairlist := $pairlists -}}
  {{- if and (eq (($pairlist.method | default "") | toString) "StaticPairList") (empty ((get $exchange "pair_whitelist") | default list)) -}}
    {{- fail (printf "%s: config.public.exchange.pair_whitelist is required when using StaticPairList" $instance._name) -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Validate the whole chart.
*/}}
{{- define "freqtrade.validateAll" -}}
{{- $names := dict -}}
{{- range $i, $bot := (.Values.bots | default list) -}}
  {{- if ($bot.enabled | default true) -}}
    {{- $name := required (printf "bots[%d].name is required" $i) $bot.name -}}
    {{- if eq $name "dashboard" -}}
      {{- fail "bot name 'dashboard' is reserved" -}}
    {{- end -}}
    {{- if not (regexMatch "^[a-z0-9]([-a-z0-9]*[a-z0-9])?$" $name) -}}
      {{- fail (printf "bot name %q must be a DNS-1123 compatible label" $name) -}}
    {{- end -}}
    {{- if hasKey $names $name -}}
      {{- fail (printf "duplicate bot name %q" $name) -}}
    {{- end -}}
    {{- $_ := set $names $name true -}}
    {{- $instance := fromYaml (include "freqtrade.normalizeBot" (dict "root" $ "bot" $bot)) -}}
    {{- include "freqtrade.instance.validate" (dict "root" $ "instance" $instance) -}}
  {{- end -}}
{{- end -}}
{{- if .Values.dashboard.enabled -}}
  {{- $dashboard := fromYaml (include "freqtrade.normalizeDashboard" (dict "root" . "dashboard" .Values.dashboard)) -}}
  {{- include "freqtrade.instance.validate" (dict "root" . "instance" $dashboard) -}}
  {{- $jobCfg := $dashboard.dataJobs.downloadData | default dict -}}
  {{- if and $dashboard.dataJobs.enabled $jobCfg.enabled -}}
    {{- if not $dashboard.persistence.enabled -}}
      {{- fail "dashboard.dataJobs.downloadData requires dashboard.persistence.enabled=true" -}}
    {{- end -}}
    {{- if empty ($jobCfg.pairs | default list) -}}
      {{- fail "dashboard.dataJobs.downloadData.pairs must not be empty when enabled" -}}
    {{- end -}}
    {{- if empty ($jobCfg.timeframes | default list) -}}
      {{- fail "dashboard.dataJobs.downloadData.timeframes must not be empty when enabled" -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- end -}}

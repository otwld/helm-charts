{{/*
Shared volume mounts for dashboard data jobs.
*/}}
{{- define "freqtrade.dashboard.dataJobName" -}}
{{- $base := printf "%s-data" (include "freqtrade.instance.fullname" (dict "root" .root "instance" .instance)) | trunc 52 | trimSuffix "-" -}}
{{- if .scheduled -}}
{{- $base -}}
{{- else -}}
{{- $identity := dict "chartVersion" .root.Chart.Version "spec" .spec -}}
{{- printf "%s-%s" $base ((toYaml $identity) | sha256sum | trunc 8) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Shared volume mounts for dashboard data jobs.
*/}}
{{- define "freqtrade.dashboard.dataJobVolumeMounts" -}}
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
- name: user-data
  mountPath: {{ .instance.persistence.mountPath }}
{{- end -}}

{{/*
Shared volumes for dashboard data jobs.
*/}}
{{- define "freqtrade.dashboard.dataJobVolumes" -}}
- name: public-config
  configMap:
    name: {{ include "freqtrade.instance.publicConfigName" . }}
{{- if eq (include "freqtrade.instance.privateConfigEnabled" .) "true" }}
- name: private-config
  secret:
    secretName: {{ include "freqtrade.instance.privateConfigSecretName" . }}
{{- end }}
- name: user-data
  persistentVolumeClaim:
    claimName: {{ include "freqtrade.instance.userDataClaimName" . }}
{{- end -}}

{{/*
Container spec for dashboard data jobs.
*/}}
{{- define "freqtrade.dashboard.dataJobContainer" -}}
{{- $root := .root -}}
{{- $instance := .instance -}}
{{- $job := .job -}}
{{- $image := mergeOverwrite (deepCopy ($root.Values.global.image | default dict)) ($instance.image | default dict) -}}
{{- $resources := default $root.Values.global.resources $job.resources -}}
- name: download-data
  image: "{{ $image.repository }}:{{ $image.tag }}"
  imagePullPolicy: {{ $image.pullPolicy }}
  {{- with $root.Values.global.containerSecurityContext }}
  securityContext:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  args:
    - download-data
    - --config
    - /etc/freqtrade/config.json
    {{- if eq (include "freqtrade.instance.privateConfigEnabled" (dict "root" $root "instance" $instance)) "true" }}
    - --config
    - /etc/freqtrade/config-private.json
    {{- end }}
    - --days
    - {{ $job.days | quote }}
    {{- if $job.erase }}
    - --erase
    {{- end }}
    - --pairs
    {{- range $job.pairs }}
    - {{ . | quote }}
    {{- end }}
    - --timeframes
    {{- range $job.timeframes }}
    - {{ . | quote }}
    {{- end }}
    {{- range ($job.extraArgs | default list) }}
    - {{ . | quote }}
    {{- end }}
  resources:
    {{- toYaml $resources | nindent 4 }}
  volumeMounts:
    {{- include "freqtrade.dashboard.dataJobVolumeMounts" (dict "root" $root "instance" $instance) | nindent 4 }}
{{- end -}}

{{/*
Shared spec body for dashboard data jobs.
*/}}
{{- define "freqtrade.dashboard.dataJobSpec" -}}
{{- $root := .root -}}
{{- $instance := .instance -}}
{{- $job := .job -}}
{{- $image := .image -}}
{{- $selectorLabels := include "freqtrade.selectorLabels" (dict "root" $root "instance" $instance) | fromYaml -}}
{{- $jobAffinity := deepCopy ($root.Values.global.affinity | default dict) -}}
{{- $podAffinity := deepCopy ((get $jobAffinity "podAffinity") | default dict) -}}
{{- $requiredAffinity := ((get $podAffinity "requiredDuringSchedulingIgnoredDuringExecution") | default list) -}}
{{- $term := dict "labelSelector" (dict "matchLabels" $selectorLabels) "topologyKey" "kubernetes.io/hostname" -}}
{{- $_ := set $podAffinity "requiredDuringSchedulingIgnoredDuringExecution" (append $requiredAffinity $term) -}}
{{- $_ := set $jobAffinity "podAffinity" $podAffinity -}}
backoffLimit: {{ $job.backoffLimit }}
ttlSecondsAfterFinished: {{ $job.ttlSecondsAfterFinished }}
{{- with $job.activeDeadlineSeconds }}
activeDeadlineSeconds: {{ . }}
{{- end }}
template:
  metadata:
    labels:
      {{- include "freqtrade.selectorLabels" (dict "root" $root "instance" $instance) | nindent 6 }}
  spec:
    restartPolicy: OnFailure
    serviceAccountName: {{ include "freqtrade.serviceAccountName" $root }}
    automountServiceAccountToken: {{ $root.Values.global.serviceAccount.automountToken }}
    {{- with $image.pullSecrets }}
    imagePullSecrets:
      {{- toYaml . | nindent 6 }}
    {{- end }}
    {{- with $root.Values.global.podSecurityContext }}
    securityContext:
      {{- toYaml . | nindent 6 }}
    {{- end }}
    {{- with $jobAffinity }}
    affinity:
      {{- toYaml . | nindent 6 }}
    {{- end }}
    containers:
      {{- include "freqtrade.dashboard.dataJobContainer" (dict "root" $root "instance" $instance "job" $job) | nindent 6 }}
    volumes:
      {{- include "freqtrade.dashboard.dataJobVolumes" (dict "root" $root "instance" $instance) | nindent 6 }}
{{- end -}}

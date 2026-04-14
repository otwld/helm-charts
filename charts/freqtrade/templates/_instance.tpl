{{/*
Render all core resources for one normalized instance.
*/}}
{{- define "freqtrade.instance.renderAll" -}}
{{- $parts := list
  (include "freqtrade.instance.configmap" .)
  (include "freqtrade.instance.secret" .)
  (include "freqtrade.instance.telegramSecret" .)
  (include "freqtrade.instance.externalSecret" .)
  (include "freqtrade.instance.userDataPvc" .)
  (include "freqtrade.instance.strategyPvc" .)
  (include "freqtrade.instance.headlessService" .)
  (include "freqtrade.instance.apiService" .)
  (include "freqtrade.instance.ingress" .)
  (include "freqtrade.instance.networkPolicy" .)
  (include "freqtrade.instance.statefulSet" .)
-}}
{{- range $part := $parts -}}
  {{- $rendered := trim $part -}}
  {{- if $rendered -}}
{{ printf "%s\n" $rendered }}
  {{- end -}}
{{- end -}}
{{- end -}}

{{- define "freqtrade.instance.configmap" -}}
{{- $publicConfig := include "freqtrade.instance.effectivePublicConfig" . | fromYaml -}}
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "freqtrade.instance.publicConfigName" . }}
  labels:
    {{- include "freqtrade.commonLabels" . | nindent 4 }}
data:
  config.json: |
    {{- $publicConfig | toPrettyJson | nindent 4 }}
{{- end -}}

{{- define "freqtrade.instance.secret" -}}
{{- if and (not .instance.config.existingSecret) (not .instance.config.externalSecret.enabled) (not (empty (.instance.config.secret | default dict))) -}}
---
apiVersion: v1
kind: Secret
metadata:
  name: {{ include "freqtrade.instance.generatedPrivateConfigSecretName" . }}
  labels:
    {{- include "freqtrade.commonLabels" . | nindent 4 }}
type: Opaque
stringData:
  {{ default "config-private.json" .instance.config.existingSecretKey }}: |
    {{- (.instance.config.secret | default dict) | toPrettyJson | nindent 4 }}
{{- end -}}
{{- end -}}

{{- define "freqtrade.instance.telegramSecret" -}}
{{- if eq (include "freqtrade.instance.telegramEnabled" .) "true" -}}
---
apiVersion: v1
kind: Secret
metadata:
  name: {{ include "freqtrade.instance.telegramSecretName" . }}
  labels:
    {{- include "freqtrade.commonLabels" . | nindent 4 }}
type: Opaque
stringData:
  config-telegram.json: |
    {{- (include "freqtrade.instance.telegramConfig" . | fromYaml) | toPrettyJson | nindent 4 }}
{{- end -}}
{{- end -}}

{{- define "freqtrade.instance.externalSecret" -}}
{{- if .instance.config.externalSecret.enabled -}}
---
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: {{ include "freqtrade.instance.generatedPrivateConfigSecretName" . }}
  labels:
    {{- include "freqtrade.commonLabels" . | nindent 4 }}
spec:
  refreshInterval: {{ .instance.config.externalSecret.refreshInterval | quote }}
  secretStoreRef:
    name: {{ .instance.config.externalSecret.secretStoreRef.name | quote }}
    kind: {{ .instance.config.externalSecret.secretStoreRef.kind | quote }}
  target:
    name: {{ include "freqtrade.instance.privateConfigSecretName" . }}
    creationPolicy: {{ .instance.config.externalSecret.target.creationPolicy | quote }}
  {{- with .instance.config.externalSecret.data }}
  data:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with .instance.config.externalSecret.dataFrom }}
  dataFrom:
    {{- toYaml . | nindent 4 }}
  {{- end }}
{{- end -}}
{{- end -}}

{{- define "freqtrade.instance.userDataPvc" -}}
{{- if and .instance.persistence.enabled (not .instance.persistence.existingClaim) -}}
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: {{ include "freqtrade.instance.userDataClaimName" . }}
  labels:
    {{- include "freqtrade.commonLabels" . | nindent 4 }}
  {{- with .instance.persistence.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  accessModes:
    {{- toYaml .instance.persistence.accessModes | nindent 4 }}
  resources:
    requests:
      storage: {{ .instance.persistence.size }}
  {{- with .instance.persistence.storageClassName }}
  storageClassName: {{ . | quote }}
  {{- end }}
{{- end -}}
{{- end -}}

{{- define "freqtrade.instance.strategyPvc" -}}
{{- if and (eq .instance.strategy.source.type "volume") (not .instance.strategy.source.volume.existingClaim) -}}
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: {{ include "freqtrade.instance.strategyClaimName" . }}
  labels:
    {{- include "freqtrade.commonLabels" . | nindent 4 }}
  {{- with .instance.strategy.source.volume.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  accessModes:
    {{- toYaml .instance.strategy.source.volume.accessModes | nindent 4 }}
  resources:
    requests:
      storage: {{ .instance.strategy.source.volume.size }}
  {{- with .instance.strategy.source.volume.storageClassName }}
  storageClassName: {{ . | quote }}
  {{- end }}
{{- end -}}
{{- end -}}

{{- define "freqtrade.instance.headlessService" -}}
---
apiVersion: v1
kind: Service
metadata:
  name: {{ include "freqtrade.instance.headlessServiceName" . }}
  labels:
    {{- include "freqtrade.commonLabels" . | nindent 4 }}
spec:
  clusterIP: None
  publishNotReadyAddresses: true
  selector:
    {{- include "freqtrade.selectorLabels" . | nindent 4 }}
  ports:
    - name: http
      port: {{ .instance.api.port }}
      targetPort: http
      protocol: TCP
{{- end -}}

{{- define "freqtrade.instance.apiService" -}}
{{- if .instance.api.enabled -}}
---
apiVersion: v1
kind: Service
metadata:
  name: {{ include "freqtrade.instance.apiServiceName" . }}
  labels:
    {{- include "freqtrade.commonLabels" . | nindent 4 }}
  {{- with .instance.service.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  type: {{ .instance.service.type }}
  selector:
    {{- include "freqtrade.selectorLabels" . | nindent 4 }}
  ports:
    - name: http
      port: {{ .instance.api.port }}
      targetPort: http
      protocol: TCP
{{- end -}}
{{- end -}}

{{- define "freqtrade.instance.ingress" -}}
{{- if .instance.ingress.enabled -}}
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ include "freqtrade.instance.apiServiceName" . }}
  labels:
    {{- include "freqtrade.commonLabels" . | nindent 4 }}
  {{- with .instance.ingress.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  {{- with .instance.ingress.className }}
  ingressClassName: {{ . }}
  {{- end }}
  rules:
    - host: {{ .instance.ingress.host | quote }}
      http:
        paths:
          - path: {{ .instance.ingress.path | quote }}
            pathType: {{ .instance.ingress.pathType }}
            backend:
              service:
                name: {{ include "freqtrade.instance.apiServiceName" . }}
                port:
                  name: http
  {{- with .instance.ingress.tls }}
  tls:
    {{- toYaml . | nindent 4 }}
  {{- end }}
{{- end -}}
{{- end -}}

{{- define "freqtrade.instance.networkPolicy" -}}
{{- $netpol := mergeOverwrite (deepCopy (.root.Values.global.networkPolicy | default dict)) (.instance.networkPolicy | default dict) -}}
{{- if $netpol.enabled -}}
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: {{ include "freqtrade.instance.apiServiceName" . }}
  labels:
    {{- include "freqtrade.commonLabels" . | nindent 4 }}
spec:
  podSelector:
    matchLabels:
      {{- include "freqtrade.selectorLabels" . | nindent 6 }}
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - ports:
        - protocol: TCP
          port: {{ .instance.api.port }}
      {{- with $netpol.ingress.from }}
      from:
        {{- toYaml . | nindent 8 }}
      {{- end }}
  egress:
    {{- if $netpol.egress.allowDns }}
    - ports:
        - protocol: UDP
          port: 53
        - protocol: TCP
          port: 53
    {{- end }}
    {{- with $netpol.egress.rules }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
{{- end -}}
{{- end -}}

{{- define "freqtrade.instance.statefulSet" -}}
{{- $root := .root -}}
{{- $instance := .instance -}}
{{- $image := mergeOverwrite (deepCopy ($root.Values.global.image | default dict)) ($instance.image | default dict) -}}
{{- $resources := default $root.Values.global.resources $instance.resources -}}
{{- $podSecurityContext := default $root.Values.global.podSecurityContext $instance.podSecurityContext -}}
{{- $containerSecurityContext := default $root.Values.global.containerSecurityContext $instance.containerSecurityContext -}}
{{- $globalInitContainers := $root.Values.global.initContainers | default list -}}
{{- $globalExtraContainers := $root.Values.global.extraContainers | default list -}}
{{- $globalEnv := $root.Values.global.env | default list -}}
{{- $globalEnvFrom := $root.Values.global.envFrom | default list -}}
{{- $globalNodeSelector := $root.Values.global.nodeSelector | default dict -}}
{{- $globalAffinity := $root.Values.global.affinity | default dict -}}
{{- $globalTolerations := $root.Values.global.tolerations | default list -}}
{{- $globalSpread := $root.Values.global.topologySpreadConstraints | default list -}}
{{- $globalPriorityClass := $root.Values.global.priorityClassName | default "" -}}
{{- $terminationGracePeriodSeconds := coalesce $instance.terminationGracePeriodSeconds $root.Values.global.terminationGracePeriodSeconds -}}
{{- $podLabels := mergeOverwrite (deepCopy ($root.Values.global.podLabels | default dict)) ($instance.podLabels | default dict) -}}
{{- $strategyInit := include "freqtrade.instance.strategyInitContainer" . | trim -}}
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: {{ include "freqtrade.instance.fullname" . }}
  labels:
    {{- include "freqtrade.commonLabels" . | nindent 4 }}
spec:
  serviceName: {{ include "freqtrade.instance.headlessServiceName" . }}
  replicas: 1
  podManagementPolicy: OrderedReady
  updateStrategy:
    type: RollingUpdate
  selector:
    matchLabels:
      {{- include "freqtrade.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "freqtrade.selectorLabels" . | nindent 8 }}
        {{- with $podLabels }}
        {{- toYaml . | nindent 8 }}
        {{- end }}
      annotations:
        {{- include "freqtrade.instance.podAnnotations" . | nindent 8 }}
    spec:
      serviceAccountName: {{ include "freqtrade.serviceAccountName" $root }}
      automountServiceAccountToken: {{ $root.Values.global.serviceAccount.automountToken }}
      terminationGracePeriodSeconds: {{ $terminationGracePeriodSeconds }}
      {{- with $image.pullSecrets }}
      imagePullSecrets:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with $podSecurityContext }}
      securityContext:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- if or $strategyInit $globalInitContainers $instance.initContainers }}
      initContainers:
        {{- if $strategyInit }}
        {{- $strategyInit | nindent 8 }}
        {{- end }}
        {{- with $globalInitContainers }}
        {{- toYaml . | nindent 8 }}
        {{- end }}
        {{- with $instance.initContainers }}
        {{- toYaml . | nindent 8 }}
        {{- end }}
      {{- end }}
      containers:
        - name: freqtrade
          image: "{{ $image.repository }}:{{ $image.tag }}"
          imagePullPolicy: {{ $image.pullPolicy }}
          {{- with $containerSecurityContext }}
          securityContext:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- with $instance.command }}
          command:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- if $instance.args }}
          args:
            {{- toYaml $instance.args | nindent 12 }}
          {{- else }}
          args:
            {{- include "freqtrade.instance.containerArgs" . | nindent 12 }}
          {{- end }}
          {{- if or $globalEnvFrom $instance.envFrom }}
          envFrom:
            {{- with $globalEnvFrom }}
            {{- toYaml . | nindent 12 }}
            {{- end }}
            {{- with $instance.envFrom }}
            {{- toYaml . | nindent 12 }}
            {{- end }}
          {{- end }}
          {{- if or $globalEnv $instance.env }}
          env:
            {{- with $globalEnv }}
            {{- toYaml . | nindent 12 }}
            {{- end }}
            {{- with $instance.env }}
            {{- toYaml . | nindent 12 }}
            {{- end }}
          {{- end }}
          ports:
            - name: http
              containerPort: {{ $instance.api.port }}
              protocol: TCP
          resources:
            {{- toYaml $resources | nindent 12 }}
          {{- with (default ($root.Values.global.lifecycle | default dict) $instance.lifecycle) }}
          {{- if . }}
          lifecycle:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- end }}
          volumeMounts:
            {{- include "freqtrade.instance.volumeMounts" . | nindent 12 }}
          {{- include "freqtrade.instance.statefulProbes" . | nindent 10 }}
        {{- with $globalExtraContainers }}
        {{- toYaml . | nindent 8 }}
        {{- end }}
        {{- with $instance.extraContainers }}
        {{- toYaml . | nindent 8 }}
        {{- end }}
      volumes:
        {{- include "freqtrade.instance.volumes" . | nindent 8 }}
      {{- with (default $globalNodeSelector $instance.nodeSelector) }}
      {{- if . }}
      nodeSelector:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- end }}
      {{- with (default $globalAffinity $instance.affinity) }}
      {{- if . }}
      affinity:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- end }}
      {{- with (default $globalTolerations $instance.tolerations) }}
      {{- if . }}
      tolerations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- end }}
      {{- with (default $globalSpread $instance.topologySpreadConstraints) }}
      {{- if . }}
      topologySpreadConstraints:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- end }}
      {{- with (default $globalPriorityClass $instance.priorityClassName) }}
      {{- if . }}
      priorityClassName: {{ . }}
      {{- end }}
      {{- end }}
{{- end -}}

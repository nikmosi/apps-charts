{{/*
Expand the name of the chart.
*/}}
{{- define "ntfy.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "ntfy.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "ntfy.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels.
*/}}
{{- define "ntfy.labels" -}}
helm.sh/chart: {{ include "ntfy.chart" . }}
{{ include "ntfy.selectorLabels" . }}
app.kubernetes.io/component: server
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/part-of: ntfy
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels.
*/}}
{{- define "ntfy.selectorLabels" -}}
app.kubernetes.io/name: {{ include "ntfy.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Labels for immutable StatefulSet volumeClaimTemplates.
*/}}
{{- define "ntfy.volumeClaimLabels" -}}
helm.sh/chart: {{ include "ntfy.chart" . }}
{{ include "ntfy.selectorLabels" . }}
app.kubernetes.io/component: server
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Create the name of the service account to use.
*/}}
{{- define "ntfy.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "ntfy.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the name of the authentik forward-auth middleware.
*/}}
{{- define "ntfy.authentikMiddlewareName" -}}
{{- default (printf "%s-authentik-forward-auth" (include "ntfy.fullname" .)) .Values.ingress.authentik.middlewareName | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a Traefik Kubernetes CRD middleware reference for Ingress annotations.
*/}}
{{- define "ntfy.authentikMiddlewareRef" -}}
{{- printf "%s-%s@kubernetescrd" .Release.Namespace (include "ntfy.authentikMiddlewareName" .) }}
{{- end }}

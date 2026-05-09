{{/*
Expand the name of the chart.
*/}}
{{- define "zipline.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "zipline.fullname" -}}
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
{{- define "zipline.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels.
*/}}
{{- define "zipline.labels" -}}
helm.sh/chart: {{ include "zipline.chart" . }}
{{ include "zipline.selectorLabels" . }}
app.kubernetes.io/component: zipline
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels.
*/}}
{{- define "zipline.selectorLabels" -}}
app.kubernetes.io/name: {{ include "zipline.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
PostgreSQL selector labels.
*/}}
{{- define "zipline.postgresqlSelectorLabels" -}}
{{ include "zipline.selectorLabels" . }}
app.kubernetes.io/component: postgresql
{{- end }}

{{/*
Create the name of the service account to use.
*/}}
{{- define "zipline.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "zipline.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Zipline secret name.
*/}}
{{- define "zipline.secretName" -}}
{{- default (printf "%s-secrets" (include "zipline.fullname" .)) .Values.secrets.existingSecret }}
{{- end }}

{{/*
PostgreSQL service name.
*/}}
{{- define "zipline.postgresqlServiceName" -}}
{{- printf "%s-postgresql" (include "zipline.fullname" .) }}
{{- end }}

{{/*
PVC names.
*/}}
{{- define "zipline.uploadsPvcName" -}}
{{- printf "%s-uploads" (include "zipline.fullname" .) }}
{{- end }}

{{- define "zipline.publicPvcName" -}}
{{- printf "%s-public" (include "zipline.fullname" .) }}
{{- end }}

{{- define "zipline.themesPvcName" -}}
{{- printf "%s-themes" (include "zipline.fullname" .) }}
{{- end }}

{{- define "zipline.postgresqlPvcName" -}}
{{- printf "%s-postgresql" (include "zipline.fullname" .) }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "traffic-noise.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels for wrapper-owned resources.
*/}}
{{- define "traffic-noise.labels" -}}
helm.sh/chart: {{ include "traffic-noise.chart" . }}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: locust
{{- end -}}

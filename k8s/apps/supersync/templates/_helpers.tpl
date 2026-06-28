{{- define "supersync.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "supersync.fullname" -}}
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

{{- define "supersync.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "supersync.labels" -}}
helm.sh/chart: {{ include "supersync.chart" . }}
{{ include "supersync.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "supersync.selectorLabels" -}}
app.kubernetes.io/name: {{ include "supersync.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "supersync.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "supersync.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{- define "supersync.databaseUrl" -}}
{{- if .Values.secret.databaseUrl }}
{{- .Values.secret.databaseUrl }}
{{- else }}
{{- $pg := .Values.postgresql -}}
{{- $user := $pg.auth.username | default "supersync" -}}
{{- $db := $pg.auth.database | default "supersync" -}}
{{- $host := (include "supersync.fullname" .) | printf "%s-postgresql" -}}
{{- $pass := $pg.auth.password | default "" -}}
{{- printf "postgresql://%s:%s@%s:5432/%s" $user $pass $host $db -}}
{{- end }}
{{- end }}

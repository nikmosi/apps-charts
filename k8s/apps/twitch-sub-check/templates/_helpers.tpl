{{/*
Expand the name of the chart.
*/}}
{{- define "twitch-sub-check.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "twitch-sub-check.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "twitch-sub-check.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels.
*/}}
{{- define "twitch-sub-check.labels" -}}
helm.sh/chart: {{ include "twitch-sub-check.chart" . }}
{{ include "twitch-sub-check.selectorLabels" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels.
*/}}
{{- define "twitch-sub-check.selectorLabels" -}}
app.kubernetes.io/name: {{ include "twitch-sub-check.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Create the service account name.
*/}}
{{- define "twitch-sub-check.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "twitch-sub-check.fullname" .) .Values.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{/*
Application credentials secret name.
*/}}
{{- define "twitch-sub-check.credentialsSecretName" -}}
{{- default (printf "%s-credentials" (include "twitch-sub-check.fullname" .)) .Values.credentials.existingSecret -}}
{{- end -}}

{{/*
Application PVC name.
*/}}
{{- define "twitch-sub-check.pvcName" -}}
{{- default (printf "%s-data" (include "twitch-sub-check.fullname" .)) .Values.persistence.existingClaim -}}
{{- end -}}

{{/*
Application image reference.
*/}}
{{- define "twitch-sub-check.image" -}}
{{- if .Values.image.digest -}}
{{- printf "%s@%s" .Values.image.repository .Values.image.digest -}}
{{- else -}}
{{- printf "%s:%s" .Values.image.repository (.Values.image.tag | default .Chart.AppVersion) -}}
{{- end -}}
{{- end -}}

{{/*
RabbitMQ names and image reference.
*/}}
{{- define "twitch-sub-check.rabbitmqFullname" -}}
{{- printf "%s-rabbitmq" (include "twitch-sub-check.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "twitch-sub-check.rabbitmqSecretName" -}}
{{- default (printf "%s-auth" (include "twitch-sub-check.rabbitmqFullname" .)) .Values.rabbitmq.auth.existingSecret -}}
{{- end -}}

{{- define "twitch-sub-check.rabbitmqImage" -}}
{{- if .Values.rabbitmq.image.digest -}}
{{- printf "%s@%s" .Values.rabbitmq.image.repository .Values.rabbitmq.image.digest -}}
{{- else -}}
{{- printf "%s:%s" .Values.rabbitmq.image.repository .Values.rabbitmq.image.tag -}}
{{- end -}}
{{- end -}}

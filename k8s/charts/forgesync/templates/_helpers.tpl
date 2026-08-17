{{/*
Expand the name of the chart.
*/}}
{{- define "forgesync.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "forgesync.fullname" -}}
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
{{- define "forgesync.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "forgesync.labels" -}}
helm.sh/chart: {{ include "forgesync.chart" . }}
{{ include "forgesync.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "forgesync.selectorLabels" -}}
app.kubernetes.io/name: {{ include "forgesync.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "forgesync.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{- default (include "forgesync.fullname" .) .Values.serviceAccount.name -}}
{{- else -}}
    {{- default "default" .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{/*
CLI arguments for forgesync target
*/}}
{{- define "forgesync.args" -}}
{{- $root := .root -}}
{{- $target := .target -}}
{{- $defaults := $root.Values.defaults -}}

{{- $includePrivate := $defaults.includePrivate -}}
{{- if hasKey $target "includePrivate" -}}
  {{- $includePrivate = $target.includePrivate -}}
{{- end -}}
{{- if $includePrivate }}
- "--include-private"
{{- end }}

{{- $includeForks := $defaults.includeForks -}}
{{- if hasKey $target "includeForks" -}}
  {{- $includeForks = $target.includeForks -}}
{{- end -}}
{{- if $includeForks }}
- "--include-forks"
{{- end }}

{{- $remirror := $defaults.remirror -}}
{{- if hasKey $target "remirror" -}}
  {{- $remirror = $target.remirror -}}
{{- end -}}
{{- if $remirror }}
- "--remirror"
{{- end }}

{{- $purge := $defaults.purge -}}
{{- if hasKey $target "purge" -}}
  {{- $purge = $target.purge -}}
{{- end -}}
{{- if $purge }}
- "--purge"
{{- end }}

{{- $skipInitial := $defaults.skipInitial -}}
{{- if hasKey $target "skipInitial" -}}
  {{- $skipInitial = $target.skipInitial -}}
{{- end -}}
{{- if $skipInitial }}
- "--skip-initial"
{{- end }}

{{- $onCommit := $defaults.onCommit -}}
{{- if hasKey $target "onCommit" -}}
  {{- $onCommit = $target.onCommit -}}
{{- end -}}
{{- if $onCommit }}
- "--on-commit"
{{- end }}

{{- $dryRun := $defaults.dryRun -}}
{{- if hasKey $target "dryRun" -}}
  {{- $dryRun = $target.dryRun -}}
{{- end -}}
{{- if $dryRun }}
- "--dry-run"
{{- end }}

{{/* Value options */}}
{{- $logLevel := $target.logLevel | default $defaults.logLevel -}}
{{- if $logLevel }}
- "--log"
- {{ $logLevel | quote }}
{{- end }}

{{- $descriptionTemplate := $target.descriptionTemplate | default $defaults.descriptionTemplate -}}
{{- if $descriptionTemplate }}
- "--description-template"
- {{ $descriptionTemplate | quote }}
{{- end }}

{{- $mirrorInterval := $target.mirrorInterval | default $defaults.mirrorInterval -}}
{{- if $mirrorInterval }}
- "--mirror-interval"
- {{ $mirrorInterval | quote }}
{{- end }}

{{/* List options */}}
{{- $includeList := $target.include | default $defaults.include -}}
{{- range $includeList }}
- "--include"
- {{ . | quote }}
{{- end }}

{{- $excludeList := $target.exclude | default $defaults.exclude -}}
{{- range $excludeList }}
- "--exclude"
- {{ . | quote }}
{{- end }}

{{- $featureList := $target.feature | default $defaults.feature -}}
{{- range $featureList }}
- "--feature"
- {{ . | quote }}
{{- end }}

{{/* Positional arguments: source and target */}}
{{- $source := $target.source | default $root.Values.source -}}
- {{ $source | quote }}
- {{ $target.target | quote }}
{{- end -}}

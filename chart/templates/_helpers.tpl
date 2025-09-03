{{/*
Expand the name of the chart.
*/}}
{{- define "application.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Platformatic installation namespace
*/}}
{{- define "install.namespace" -}}
{{- coalesce .Values.platformaticNamespace .Release.Namespace "platformatic" }}
{{- end }}

{{/*
All namespaces - returns newline-separated list
*/}}
{{- define "install.allNamespaces" -}}
{{- $appNs := .Values.applicationNamespaces }}
{{- if $appNs }}
{{- range $appNs }}
{{ . }}
{{- end }}
{{- else }}
{{- $defaultNs := include "install.namespace" $ }}
{{ $defaultNs }}
{{- end }}
{{- end }}

{{/*
ImagePullSecret - DockerConfig
*/}}
{{- define "imagePullSecret.dockerConfig" -}}
{"auths":{"{{ .registry }}":{"auth":"{{- printf "%s:%s" .user .token | b64enc -}}"}}}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "application.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s" .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "application.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "application.labels" -}}
helm.sh/chart: {{ include "application.chart" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "application.selectorLabels" -}}
app.kubernetes.io/name: {{ include "application.name" . }}
app.kubernetes.io/instance: {{ .name }}
app.kubernetes.io/partition: platformatic
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "application.serviceAccountName" -}}
platformatic
{{- end }}

{{/* External port number */}}
{{- define "service.port" -}}
80
{{- end }}

{{/* External service type */}}
{{- define "service.type" -}}
NodePort
{{- end }}

{{/* ICC databases */}}
{{- define "service.icc.databases" -}}
activities risk_cold_storage control_plane cron scaler trafficante user_manager cluster_manager compliance
{{- end }}

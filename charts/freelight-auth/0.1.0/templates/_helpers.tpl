{{/*
Expand the name of the chart.
*/}}
{{- define "freelight-auth.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "freelight-auth.fullname" -}}
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
Component-scoped fully qualified name (e.g. "freelight-auth-backend",
"freelight-auth-frontend"). Pass the component name as `.Component`.
*/}}
{{- define "freelight-auth.componentFullname" -}}
{{- printf "%s-%s" (include "freelight-auth.fullname" .) .Component | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "freelight-auth.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels (shared across components)
*/}}
{{- define "freelight-auth.labels" -}}
helm.sh/chart: {{ include "freelight-auth.chart" . }}
{{ include "freelight-auth.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels (shared across components)
*/}}
{{- define "freelight-auth.selectorLabels" -}}
app.kubernetes.io/name: {{ include "freelight-auth.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Component-scoped selector labels — add app.kubernetes.io/component so
the backend Deployment doesn't accidentally select the frontend pods.
Pass `.Component` ("backend" or "frontend").
*/}}
{{- define "freelight-auth.componentSelectorLabels" -}}
{{ include "freelight-auth.selectorLabels" . }}
app.kubernetes.io/component: {{ .Component }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "freelight-auth.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "freelight-auth.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Expand the name of the chart.
*/}}
{{- define "freelight.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "freelight.fullname" -}}
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
Component-scoped fully qualified name (e.g. "freelight-backend",
"freelight-frontend"). Pass the component name as `.Component`.
*/}}
{{- define "freelight.componentFullname" -}}
{{- printf "%s-%s" (include "freelight.fullname" .) .Component | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "freelight.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels (shared across components).
*/}}
{{- define "freelight.labels" -}}
helm.sh/chart: {{ include "freelight.chart" . }}
{{ include "freelight.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels (shared across components).
*/}}
{{- define "freelight.selectorLabels" -}}
app.kubernetes.io/name: {{ include "freelight.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Component-scoped selector labels — adds app.kubernetes.io/component so
the backend Deployment doesn't accidentally select frontend pods.
*/}}
{{- define "freelight.componentSelectorLabels" -}}
{{ include "freelight.selectorLabels" . }}
app.kubernetes.io/component: {{ .Component }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "freelight.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "freelight.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

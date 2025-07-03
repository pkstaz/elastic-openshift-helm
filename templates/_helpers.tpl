{{/*
Expand the name of the chart.
*/}}
{{- define "elasticsearch-openshift.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "elasticsearch-openshift.fullname" -}}
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
{{- define "elasticsearch-openshift.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "elasticsearch-openshift.labels" -}}
helm.sh/chart: {{ include "elasticsearch-openshift.chart" . }}
{{ include "elasticsearch-openshift.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "elasticsearch-openshift.selectorLabels" -}}
app.kubernetes.io/name: {{ include "elasticsearch-openshift.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Elasticsearch cluster name
*/}}
{{- define "elasticsearch-openshift.clusterName" -}}
{{- .Values.elasticsearch.clusterName | default "elasticsearch" }}
{{- end }}

{{/*
Kibana labels
*/}}
{{- define "elasticsearch-openshift.kibana.labels" -}}
app.kubernetes.io/name: {{ include "elasticsearch-openshift.name" . }}-kibana
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: kibana
{{- end }}

{{/*
Kibana selector labels
*/}}
{{- define "elasticsearch-openshift.kibana.selectorLabels" -}}
app.kubernetes.io/name: {{ include "elasticsearch-openshift.name" . }}-kibana
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Elasticsearch service name
*/}}
{{- define "elasticsearch-openshift.elasticsearch.serviceName" -}}
{{- printf "%s-es" (include "elasticsearch-openshift.clusterName" .) }}
{{- end }}

{{/*
Elasticsearch service URL
*/}}
{{- define "elasticsearch-openshift.elasticsearch.serviceUrl" -}}
{{- printf "https://%s.%s.svc:9200" (include "elasticsearch-openshift.elasticsearch.serviceName" .) .Release.Namespace }}
{{- end }}

{{/*
Kibana service name
*/}}
{{- define "elasticsearch-openshift.kibana.serviceName" -}}
{{- printf "%s-kb-http" (include "elasticsearch-openshift.clusterName" .) }}
{{- end }}

{{/*
Namespace name
*/}}
{{- define "elasticsearch-openshift.namespace" -}}
{{- if .Values.namespace.name }}
{{- .Values.namespace.name }}
{{- else }}
{{- .Release.Namespace }}
{{- end }}
{{- end }} 
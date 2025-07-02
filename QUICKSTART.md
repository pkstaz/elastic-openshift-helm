# Quick Start Guide

This guide will help you quickly deploy Elasticsearch on OpenShift using this Helm chart.

## Prerequisites

- OpenShift 4.x cluster
- `oc` CLI tool configured and logged in
- Helm 3.x installed
- Elasticsearch Operator installed

## Quick Installation

### 1. Install OpenShift Logging Operator (REQUIRED)

**IMPORTANT**: The OpenShift Logging Operator must be installed before deploying this chart. The chart does not install the operator automatically.

**Option A: Using OpenShift Console (Recommended)**
1. Go to OpenShift Console → Operators → OperatorHub
2. Search for "OpenShift Logging"
3. Install the "OpenShift Logging" operator by Red Hat
4. Wait for the installation to complete

**Option B: Using CLI**
```bash
# Install via subscription
oc apply -f - <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: cluster-logging
  namespace: openshift-logging
spec:
  channel: stable
  installPlanApproval: Automatic
  name: cluster-logging
  source: redhat-operators
  sourceNamespace: openshift-marketplace
EOF

# Wait for operator to be ready
oc wait --for=condition=ready pod -l name=cluster-logging-operator -n openshift-logging --timeout=300s
```

**Verify operator is running**:
```bash
oc get pods -n openshift-logging -l name=cluster-logging-operator
```

### 2. Deploy Elasticsearch

**Prerequisite Check**: Ensure the operator is running before proceeding:
```bash
oc get pods -n openshift-logging -l name=cluster-logging-operator
```

**Deploy the chart**:
```bash
# Clone the repository
git clone https://github.com/pkstaz/elastic-openshift-helm.git
cd elastic-openshift-helm

# Install with default settings (3 nodes, 2Gi RAM each)
helm install my-elasticsearch . --namespace elasticsearch --create-namespace

# OR install with production settings
helm install my-elasticsearch . -f values-production.yaml --namespace elasticsearch --create-namespace

# OR install with development settings
helm install my-elasticsearch . -f values-dev.yaml --namespace elasticsearch --create-namespace
```

### 3. Verify Installation

```bash
# Check cluster status
oc get elasticsearch -n elasticsearch

# Check pods
oc get pods -n elasticsearch

# Check services
oc get services -n elasticsearch

# Check routes (if enabled)
oc get routes -n elasticsearch
```

### 4. Access Elasticsearch

#### Get the password:
```bash
oc get secret quickstart-es-elastic-user -n elasticsearch -o jsonpath='{.data.elastic}' | base64 -d
```

#### Test connection:
```bash
# Internal access
oc exec -n elasticsearch -c elasticsearch $(oc get pods -n elasticsearch -l cluster-name=elasticsearch -o jsonpath='{.items[0].metadata.name}') -- curl -k -u kubeadmin:$(oc get secret elasticsearch-es-elastic-user -n elasticsearch -o jsonpath='{.data.elastic}' | base64 -d) https://localhost:9200

# External access (if routes enabled)
curl -k -u elastic:$(oc get secret quickstart-es-elastic-user -n elasticsearch -o jsonpath='{.data.elastic}' | base64 -d) https://your-route-hostname
```

#### Access ElasticVue UI:
```bash
# Get the route URL
oc get route -n elasticsearch | grep elasticvue
```

## Common Operations

### Scale the cluster:
```bash
# Scale to 5 nodes
helm upgrade my-elasticsearch . --set elasticsearch.nodeSets.count=5 -n elasticsearch
```

### Update resources:
```bash
# Increase memory to 4Gi
helm upgrade my-elasticsearch . --set elasticsearch.nodeSets.resources.requests.memory=4Gi -n elasticsearch
```

### Uninstall:
```bash
helm uninstall my-elasticsearch -n elasticsearch
oc delete namespace elasticsearch
```

## Troubleshooting

### Check logs:
```bash
# Elasticsearch logs
oc logs -n elasticsearch -l cluster-name=elasticsearch

# ElasticVue logs
oc logs -n elasticsearch -l app.kubernetes.io/name=elasticsearch-openshift-elasticvue
```

### Check events:
```bash
oc get events -n elasticsearch --sort-by='.lastTimestamp'
```

### Check operator status:
```bash
oc get pods -n openshift-logging -l name=cluster-logging-operator
```

## Next Steps

1. **Configure indices**: Create your first index
2. **Set up monitoring**: Configure Prometheus/Grafana
3. **Configure backup**: Set up snapshot repositories
4. **Security hardening**: Review and adjust security settings

For more detailed information, see the [README.md](README.md) file. 
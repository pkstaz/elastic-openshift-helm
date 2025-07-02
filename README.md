# Elasticsearch OpenShift Helm Chart

A Helm chart for deploying Elasticsearch on OpenShift using the official Elasticsearch Operator with ElasticVue for web-based management.

## Features

- 🚀 **Elasticsearch Operator**: Uses the official Elasticsearch Operator for Kubernetes
- 🔐 **Security**: Built-in authentication and TLS support
- 🌐 **OpenShift Native**: Routes for external access, SecurityContextConstraints compliance
- 📊 **ElasticVue**: Web-based Elasticsearch management interface
- 🔧 **Configurable**: Highly customizable through values.yaml
- 📈 **Monitoring Ready**: Health checks and resource management

## Prerequisites

- OpenShift 4.x cluster
- **OpenShift Logging Operator installed in the cluster** (REQUIRED - not installed by this chart)
- Helm 3.x
- `oc` CLI tool configured

**Important**: The OpenShift Logging Operator (which includes the Elasticsearch operator) must be installed separately before deploying this chart. This chart only deploys the Elasticsearch cluster, not the operator itself.

## Installation

### 1. Install the OpenShift Logging Operator

**IMPORTANT**: The OpenShift Logging Operator must be installed in your cluster before deploying this chart. The chart does not install the operator automatically.

You can install the operator using one of these methods:

**Method 1: Using OpenShift OperatorHub (Recommended)**
1. Go to OpenShift Console → Operators → OperatorHub
2. Search for "OpenShift Logging"
3. Install the "OpenShift Logging" operator by Red Hat
4. Wait for the installation to complete

**Method 2: Using CLI**
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

### 2. Install the Helm Chart

**Prerequisite Check**: Ensure the OpenShift Logging Operator is running:
```bash
oc get pods -n openshift-logging -l name=cluster-logging-operator
```

**Install the chart**:
```bash
# Add the repository (if using a repository)
helm repo add elastic-openshift https://your-repo-url
helm repo update

# Install the chart
helm install my-elasticsearch ./elastic-openshift-helm \
  --namespace elasticsearch \
  --create-namespace
```

### 3. Verify Installation

```bash
# Check the Elasticsearch cluster status
oc get elasticsearch -n elasticsearch

# Check the pods
oc get pods -n elasticsearch

# Check the ElasticVue deployment
oc get deployment -n elasticsearch
```

## Configuration

The following table lists the configurable parameters of the elasticsearch-openshift chart and their default values.

| Parameter | Description | Default |
|-----------|-------------|---------|
| `namespace.name` | Namespace name | `elasticsearch` |
| `namespace.create` | Create namespace | `true` |
| `elasticsearch.clusterName` | Elasticsearch cluster name | `elasticsearch` |
| `elasticsearch.indexManagement.enabled` | Enable index management | `false` |
| `elasticsearch.nodeSpec.resources.requests.memory` | Memory requests | `512Mi` |
| `elasticsearch.nodeSpec.resources.requests.cpu` | CPU requests | `100m` |
| `elasticsearch.nodeSpec.resources.limits.memory` | Memory limits | `1Gi` |
| `elasticsearch.nodeSpec.resources.limits.cpu` | CPU limits | `""` (no limit) |
| `elasticsearch.nodes[0].roles` | Node roles | `["client", "data", "master"]` |
| `elasticsearch.nodes[0].storage.size` | Storage size | `20Gi` |
| `elasticsearch.nodes[0].nodeCount` | Number of nodes | `1` |
| `elasticsearch.managementState` | Management state | `Managed` |
| `elasticsearch.redundancyPolicy` | Redundancy policy | `ZeroRedundancy` |
| `elasticvue.enabled` | Enable ElasticVue | `true` |
| `elasticvue.image.repository` | ElasticVue image | `cars10/elasticvue` |
| `elasticvue.image.tag` | ElasticVue image tag | `1.0.4` |
| `elasticvue.replicas` | ElasticVue replicas | `1` |
| `route.enabled` | Enable OpenShift routes | `true` |
| `route.host` | Route hostname | `""` (auto-generated) |
| `route.tls.enabled` | Enable TLS for routes | `true` |
| `route.tls.termination` | TLS termination type | `edge` |

### Example Custom Values

```yaml
# values-custom.yaml
namespace:
  name: my-elasticsearch
  create: true

elasticsearch:
  clusterName: production-cluster
  indexManagement:
    enabled: true
    mappings:
      - aliases: ["infra", "logs.infra"]
        name: infra
        policyRef: infra-policy
    policies:
      - phases:
          delete:
            minAge: 7d
          hot:
            actions:
              rollover:
                maxAge: 8h
        name: infra-policy
        pollInterval: 30m
  
  nodeSpec:
    resources:
      requests:
        memory: 2Gi
        cpu: 1000m
      limits:
        memory: 4Gi
        cpu: 2000m
  
  nodes:
    - roles: ["client", "data", "master"]
      storage:
        size: 100Gi
      nodeCount: 3
  
  managementState: Managed
  redundancyPolicy: SingleRedundancy

elasticvue:
  enabled: true
  replicas: 2

route:
  enabled: true
  host: "elasticsearch.mycompany.com"
```

Install with custom values:

```bash
helm install my-elasticsearch ./elastic-openshift-helm \
  --namespace my-elasticsearch \
  --create-namespace \
  -f values-custom.yaml
```

## Accessing Elasticsearch

### External Access (Routes)

If routes are enabled, you can access:

- **Elasticsearch**: `https://your-route-hostname`
- **ElasticVue UI**: `https://your-elasticvue-route-hostname`

### Internal Access

- **Elasticsearch Service**: `quickstart-es-http.elasticsearch.svc:9200`
- **ElasticVue Service**: `my-elasticsearch-elasticvue.elasticsearch.svc:8080`

### Authentication

If authentication is enabled:

```bash
# Get the elastic user password
oc get secret quickstart-es-elastic-user -n elasticsearch -o jsonpath='{.data.elastic}' | base64 -d

# Test connection
curl -k -u elastic:$(oc get secret quickstart-es-elastic-user -n elasticsearch -o jsonpath='{.data.elastic}' | base64 -d) https://localhost:9200
```

## Management

### Scaling

```bash
# Scale Elasticsearch nodes
oc patch elasticsearch quickstart -n elasticsearch --type='merge' -p='{"spec":{"nodeSets":[{"name":"default","count":5}]}}'

# Scale ElasticVue
oc scale deployment my-elasticsearch-elasticvue -n elasticsearch --replicas=3
```

### Backup and Restore

```bash
# Create a snapshot repository
curl -X PUT "localhost:9200/_snapshot/my_backup" -H 'Content-Type: application/json' -d'
{
  "type": "fs",
  "settings": {
    "location": "/usr/share/elasticsearch/data/backup"
  }
}'

# Create a snapshot
curl -X PUT "localhost:9200/_snapshot/my_backup/snapshot_1?wait_for_completion=true"
```

### Monitoring

```bash
# Check cluster health
oc exec -n elasticsearch -c elasticsearch $(oc get pods -n elasticsearch -l common.k8s.elastic.co/type=elasticsearch -o jsonpath='{.items[0].metadata.name}') -- curl -k -u elastic:$(oc get secret quickstart-es-elastic-user -n elasticsearch -o jsonpath='{.data.elastic}' | base64 -d) https://localhost:9200/_cluster/health

# Check indices
oc exec -n elasticsearch -c elasticsearch $(oc get pods -n elasticsearch -l common.k8s.elastic.co/type=elasticsearch -o jsonpath='{.items[0].metadata.name}') -- curl -k -u elastic:$(oc get secret quickstart-es-elastic-user -n elasticsearch -o jsonpath='{.data.elastic}' | base64 -d) https://localhost:9200/_cat/indices
```

## Troubleshooting

### Common Issues

1. **OpenShift Logging Operator not found**
   - Ensure the OpenShift Logging Operator is installed in `openshift-logging` namespace
   - Check operator status: `oc get pods -n openshift-logging -l name=cluster-logging-operator`
   - Install operator if missing (see installation section above)

2. **Pods stuck in Pending state**
   - Check if there are enough resources in the cluster
   - Verify storage class exists and is accessible
   - Ensure the operator is running and healthy

3. **Authentication issues**
   - Ensure the elastic user secret exists
   - Check if TLS is properly configured
   - Verify the operator has created the necessary secrets

4. **Routes not accessible**
   - Verify the route hostname is correct
   - Check if the service is running
   - Ensure the operator has created the Elasticsearch service

### Useful Commands

```bash
# Check operator status
oc get pods -n openshift-logging -l name=cluster-logging-operator

# Check Elasticsearch status
oc get elasticsearch -n elasticsearch -o yaml

# Check logs
oc logs -n elasticsearch -l cluster-name=elasticsearch

# Check events
oc get events -n elasticsearch --sort-by='.lastTimestamp'
```

## Uninstallation

```bash
# Delete the Helm release
helm uninstall my-elasticsearch -n elasticsearch

# Delete the namespace (optional)
oc delete namespace elasticsearch

# Note: This will delete all data in the cluster
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test the chart
5. Submit a pull request

## License

This project is licensed under the Apache License 2.0.

## Support

For issues and questions:
- Create an issue in the repository
- Contact the maintainer: Carlos Estay (cestay@redhat.com)
- Check the [Elasticsearch documentation](https://www.elastic.co/guide/en/elasticsearch/reference/current/index.html)
- Check the [Elasticsearch Operator documentation](https://www.elastic.co/guide/en/cloud-on-k8s/current/index.html)

## Maintainer

**Carlos Estay**
- Email: cestay@redhat.com
- GitHub: [pkstaz](https://github.com/pkstaz)
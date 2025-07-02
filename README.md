# Elasticsearch OpenShift Helm Chart

A Helm chart for deploying Elasticsearch on OpenShift using the official Elasticsearch Operator with Kibana for web-based management.

## Features

- 🚀 **Elasticsearch Operator**: Uses the official Elasticsearch Operator for Kubernetes
- 🔐 **Security**: Built-in authentication and TLS support
- 🌐 **OpenShift Native**: Routes for external access, SecurityContextConstraints compliance
- 📊 **Kibana**: Web-based Elasticsearch management interface
- 🔧 **Configurable**: Highly customizable through values.yaml
- 📈 **Monitoring Ready**: Health checks and resource management

## Prerequisites

- OpenShift 4.18+ cluster
- **Elasticsearch Operator installed in the cluster** (REQUIRED - not installed by this chart)
- Helm 3.x
- `oc` CLI tool configured

**Important**: The Elasticsearch Operator must be installed separately before deploying this chart. This chart only deploys the Elasticsearch cluster, not the operator itself.

## Installation

### 1. Install the Elasticsearch Operator

**IMPORTANT**: The Elasticsearch Operator must be installed in your cluster before deploying this chart. The chart does not install the operator automatically.

You can install the operator using one of these methods:

**Method 1: Manual installation**
```bash
# Create the namespace for the operator
oc create namespace openshift-operators-redhat

# Install the Elasticsearch Operator (compatible with OpenShift 4.18+)
oc apply -f https://download.elastic.co/downloads/eck/2.12.0/crds.yaml
oc apply -f https://download.elastic.co/downloads/eck/2.12.0/operator.yaml

# Wait for operator to be ready
oc wait --for=condition=ready pod -l name=elastic-operator -n openshift-operators-redhat --timeout=300s
```

**Method 2: Using OpenShift OperatorHub**
1. Go to OpenShift Console → Operators → OperatorHub
2. Search for "Elasticsearch"
3. Install the "Elasticsearch Operator" by Elastic
4. Wait for the installation to complete

### 2. Install the Helm Chart

**Prerequisite Check**: Ensure the Elasticsearch Operator is running:
```bash
oc get pods -n openshift-operators-redhat -l name=elastic-operator
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

# Check the Kibana deployment
oc get kibana -n elasticsearch
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
| `kibana.enabled` | Enable Kibana | `true` |
| `kibana.version` | Kibana version | `8.11.0` |
| `kibana.replicas` | Kibana replicas | `1` |
| `route.enabled` | Enable OpenShift routes | `true` |
| `route.host` | Route hostname | `""` (auto-generated) |
| `route.tls.enabled` | Enable TLS for routes | `true` |
| `route.tls.termination` | TLS termination type | `edge` |
| `podDisruptionBudget.enabled` | Enable PodDisruptionBudget | `true` |
| `podDisruptionBudget.minAvailable` | Minimum available pods | `1` |

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

kibana:
  enabled: true
  replicas: 2

route:
  enabled: true
  host: "elasticsearch.mycompany.com"

podDisruptionBudget:
  enabled: true
  minAvailable: 2  # For production with multiple nodes
```

Install with custom values:

```bash
helm install my-elasticsearch ./elastic-openshift-helm \
  --namespace my-elasticsearch \
  --create-namespace \
  -f values-custom.yaml
```

## Accessing Elasticsearch and Kibana

> **⚠️ IMPORTANT:**
> By default, external access to Kibana is via **http** (not https). Use `http://<kibana-route-host>` in your browser. If you want to enable https, you must configure TLS termination in the route and provide valid certificates.

### Quick Access Information

After installation, you can get connection details using:

```bash
# Get connection information
helm get notes my-elasticsearch -n elasticsearch
```

### External Access (Routes)

If routes are enabled, you can access:

- **Elasticsearch**: `https://your-route-hostname` (if TLS is enabled)
- **Kibana UI**: `http://your-kibana-route-hostname` (**default**)  
  If you configured TLS, use `https://your-kibana-route-hostname`

### Internal Access

- **Elasticsearch Service**: `elasticsearch-es-http.elasticsearch.svc:9200`
- **Kibana Service**: `elasticsearch-kb-kb-http.elasticsearch.svc:5601`

### Authentication

**Username**: `elastic`

**Get Password**:
```bash
oc get secret elasticsearch-es-elastic-user -o jsonpath='{.data.elastic}' | base64 -d
```

**Test Elasticsearch Connection**:
```bash
oc exec -c elasticsearch $(oc get pods -l cluster-name=elasticsearch -o jsonpath='{.items[0].metadata.name}') -- curl -k -u elastic:$(oc get secret elasticsearch-es-elastic-user -o jsonpath='{.data.elastic}' | base64 -d) https://localhost:9200
```

**Test from External**:
```bash
curl -k -u elastic:$(oc get secret elasticsearch-es-elastic-user -o jsonpath='{.data.elastic}' | base64 -d) https://your-elasticsearch-route-hostname
```

### Kibana Access

**First Time Setup**:
1. Access Kibana URL from the route (**http** by default)
2. Login with username: `elastic`
3. Password: Use the command above to get the password
4. Follow the Kibana setup wizard

**Kibana Features**:
- **Discover**: Search and explore your data
- **Visualize**: Create charts and graphs
- **Dashboard**: Build custom dashboards
- **Management**: Configure indices, users, and settings

## Monitoring and Management

### Cluster Status

```bash
# Check Elasticsearch cluster status
oc get elasticsearch elasticsearch -n elasticsearch

# Check Kibana status
oc get kibana elasticsearch-kb -n elasticsearch

# Check all pods
oc get pods -n elasticsearch -l cluster-name=elasticsearch

# Check PodDisruptionBudget
oc get pdb -n elasticsearch
```

### Cluster Health

```bash
# Get cluster health
oc exec -n elasticsearch -c elasticsearch $(oc get pods -n elasticsearch -l cluster-name=elasticsearch -o jsonpath='{.items[0].metadata.name}') -- curl -k -u elastic:$(oc get secret elasticsearch-es-elastic-user -n elasticsearch -o jsonpath='{.data.elastic}' | base64 -d) https://localhost:9200/_cluster/health

# Get cluster info
oc exec -n elasticsearch -c elasticsearch $(oc get pods -n elasticsearch -l cluster-name=elasticsearch -o jsonpath='{.items[0].metadata.name}') -- curl -k -u elastic:$(oc get secret elasticsearch-es-elastic-user -n elasticsearch -o jsonpath='{.data.elastic}' | base64 -d) https://localhost:9200/_cluster/stats

# List indices
oc exec -n elasticsearch -c elasticsearch $(oc get pods -n elasticsearch -l cluster-name=elasticsearch -o jsonpath='{.items[0].metadata.name}') -- curl -k -u elastic:$(oc get secret elasticsearch-es-elastic-user -n elasticsearch -o jsonpath='{.data.elastic}' | base64 -d) https://localhost:9200/_cat/indices
```

### Scaling

```bash
# Scale Elasticsearch nodes
oc patch elasticsearch elasticsearch -n elasticsearch --type='merge' -p='{"spec":{"nodeSets":[{"name":"default","count":3}]}}'

# Scale Kibana
oc patch kibana elasticsearch-kb -n elasticsearch --type='merge' -p='{"spec":{"count":2}}'
```

### Backup and Restore

```bash
# Create a snapshot repository
curl -X PUT "https://your-elasticsearch-route/_snapshot/my_backup" -H 'Content-Type: application/json' -d'
{
  "type": "fs",
  "settings": {
    "location": "/usr/share/elasticsearch/data/backup"
  }
}' -u elastic:$(oc get secret elasticsearch-es-elastic-user -n elasticsearch -o jsonpath='{.data.elastic}' | base64 -d) -k

# Create a snapshot
curl -X PUT "https://your-elasticsearch-route/_snapshot/my_backup/snapshot_1?wait_for_completion=true" -u elastic:$(oc get secret elasticsearch-es-elastic-user -n elasticsearch -o jsonpath='{.data.elastic}' | base64 -d) -k
```

### Logs and Debugging

```bash
# Check Elasticsearch logs
oc logs -n elasticsearch -l cluster-name=elasticsearch

# Check Kibana logs
oc logs -n elasticsearch -l common.k8s.elastic.co/type=kibana

# Check operator logs
oc logs -n openshift-operators-redhat -l name=elastic-operator

# Check events
oc get events -n elasticsearch --sort-by='.lastTimestamp'
```

## Troubleshooting

### Common Issues

1. **Elasticsearch Operator not found**
   - Ensure the Elasticsearch Operator is installed in `openshift-operators-redhat` namespace
   - Check operator status: `oc get pods -n openshift-operators-redhat -l name=elastic-operator`
   - Install operator if missing (see installation section above)

2. **Pods stuck in Pending state**
   - Check if there are enough resources in the cluster
   - Verify storage class exists and is accessible
   - Ensure the operator is running and healthy

3. **Authentication issues**
   - Ensure the elastic user secret exists: `oc get secret elasticsearch-es-elastic-user -n elasticsearch`
   - Check if TLS is properly configured
   - Verify the operator has created the necessary secrets

4. **Routes not accessible**
   - Verify the route hostname is correct
   - Check if the service is running
   - Ensure the operator has created the Elasticsearch service

5. **Kibana not starting**
   - Check Kibana status: `oc get kibana elasticsearch-kb -n elasticsearch`
   - Verify Elasticsearch cluster is healthy
   - Check Kibana logs for errors

6. **PodDisruptionBudget issues**
   - Check PDB status: `oc get pdb -n elasticsearch`
   - Verify node count matches PDB configuration
   - Adjust PDB settings if needed

### Useful Commands

```bash
# Check operator status
oc get pods -n openshift-operators-redhat -l name=elastic-operator

# Check Elasticsearch status
oc get elasticsearch elasticsearch -n elasticsearch -o yaml

# Check Kibana status
oc get kibana elasticsearch-kb -n elasticsearch -o yaml

# Check all resources
oc get all -n elasticsearch

# Check secrets
oc get secrets -n elasticsearch | grep elastic

# Check routes
oc get routes -n elasticsearch
```

## Security and Best Practices

### Security Considerations

1. **TLS/SSL**: The cluster uses self-signed certificates by default. For production:
   - Configure proper TLS certificates
   - Use certificate management solutions (cert-manager, etc.)

2. **Authentication**: 
   - Change default passwords after first login
   - Use role-based access control (RBAC)
   - Consider integrating with external authentication providers

3. **Network Security**:
   - Use network policies to restrict pod-to-pod communication
   - Configure firewall rules for external access
   - Use private networks when possible

### Production Recommendations

1. **Resource Planning**:
   - Use dedicated nodes for Elasticsearch
   - Allocate sufficient memory (at least 2GB per node)
   - Use SSD storage for better performance

2. **High Availability**:
   - Deploy at least 3 nodes for production
   - Configure proper replica settings
   - Use multiple availability zones

3. **Monitoring**:
   - Set up monitoring with Prometheus/Grafana
   - Configure alerting for cluster health
   - Monitor resource usage and performance

4. **Backup Strategy**:
   - Configure regular snapshots
   - Test restore procedures
   - Store backups in multiple locations

### PodDisruptionBudget Configuration

For different cluster sizes:

```yaml
# Single node (development)
podDisruptionBudget:
  enabled: true
  minAvailable: 1

# 3 nodes (staging)
podDisruptionBudget:
  enabled: true
  minAvailable: 2

# 5+ nodes (production)
podDisruptionBudget:
  enabled: true
  minAvailable: 3
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

This project is licensed under the MIT License.

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
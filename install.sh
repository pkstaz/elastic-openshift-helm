#!/bin/bash

# Elasticsearch OpenShift Helm Chart Installation Script
# This script automates the installation of Elasticsearch on OpenShift

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
RELEASE_NAME="elasticsearch"
NAMESPACE="elasticsearch"
VALUES_FILE=""
OPERATOR_VERSION="2.11.0"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Prerequisites:"
    echo "  - OpenShift Logging Operator must be installed in the cluster"
    echo "  - OpenShift 4.x cluster with oc CLI configured"
    echo "  - Helm 3.x installed"
    echo ""
    echo "Options:"
    echo "  -r, --release-name NAME     Helm release name (default: elasticsearch)"
    echo "  -n, --namespace NAME        Namespace name (default: elasticsearch)"
    echo "  -f, --values FILE           Values file to use (default: values.yaml)"
    echo "  -o, --operator-version VER  Elasticsearch Operator version to check (default: 2.11.0)"
    echo "  -h, --help                  Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Install with default settings"
    echo "  $0 -f values-production.yaml         # Install with production settings"
    echo "  $0 -f values-dev.yaml -n elastic-dev # Install in dev namespace"
    echo ""
    echo "Note: This script does not install the OpenShift Logging Operator."
echo "      Please install it manually before running this script."
    echo ""
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if oc is installed
    if ! command -v oc &> /dev/null; then
        print_error "oc CLI is not installed. Please install OpenShift CLI."
        exit 1
    fi
    
    # Check if helm is installed
    if ! command -v helm &> /dev/null; then
        print_error "Helm is not installed. Please install Helm 3.x."
        exit 1
    fi
    
    # Check if user is logged in to OpenShift
    if ! oc whoami &> /dev/null; then
        print_error "Not logged in to OpenShift. Please run 'oc login' first."
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

# Function to check OpenShift Logging Operator
check_operator() {
    print_status "Checking OpenShift Logging Operator..."
    
    # Check if operator namespace exists
    if ! oc get namespace openshift-logging &> /dev/null; then
        print_error "OpenShift Logging Operator namespace 'openshift-logging' not found."
        print_error "Please install the OpenShift Logging Operator first using one of these methods:"
        echo ""
        echo "Method 1: Using OpenShift Console (Recommended)"
        echo "  1. Go to OpenShift Console → Operators → OperatorHub"
        echo "  2. Search for 'OpenShift Logging'"
        echo "  3. Install the 'OpenShift Logging' operator by Red Hat"
        echo ""
        echo "Method 2: Using CLI"
        echo "  oc apply -f - <<EOF"
        echo "  apiVersion: operators.coreos.com/v1alpha1"
        echo "  kind: Subscription"
        echo "  metadata:"
        echo "    name: cluster-logging"
        echo "    namespace: openshift-logging"
        echo "  spec:"
        echo "    channel: stable"
        echo "    installPlanApproval: Automatic"
        echo "    name: cluster-logging"
        echo "    source: redhat-operators"
        echo "    sourceNamespace: openshift-marketplace"
        echo "  EOF"
        echo ""
        exit 1
    fi
    
    # Check if operator is running
    if ! oc get pods -n openshift-logging -l name=cluster-logging-operator &> /dev/null; then
        print_error "OpenShift Logging Operator pods not found in openshift-logging namespace."
        print_error "Please ensure the operator is properly installed and running."
        exit 1
    fi
    
    # Check if operator is ready
    if ! oc wait --for=condition=ready pod -l name=cluster-logging-operator -n openshift-logging --timeout=30s &> /dev/null; then
        print_error "OpenShift Logging Operator is not ready."
        print_error "Please wait for the operator to be fully deployed before proceeding."
        exit 1
    fi
    
    print_success "OpenShift Logging Operator is installed and ready"
}

# Function to install Helm chart
install_chart() {
    print_status "Installing Helm chart..."
    
    # Create namespace if it doesn't exist
    if ! oc get namespace ${NAMESPACE} &> /dev/null; then
        print_status "Creating namespace ${NAMESPACE}..."
        oc create namespace ${NAMESPACE}
    fi
    
    # Build helm command
    HELM_CMD="helm install ${RELEASE_NAME} . --namespace ${NAMESPACE}"
    
    if [ -n "$VALUES_FILE" ]; then
        HELM_CMD="${HELM_CMD} -f ${VALUES_FILE}"
    fi
    
    print_status "Running: ${HELM_CMD}"
    eval $HELM_CMD
    
    print_success "Helm chart installed successfully"
}

# Function to verify installation
verify_installation() {
    print_status "Verifying installation..."
    
    # Wait for Elasticsearch to be ready
    print_status "Waiting for Elasticsearch cluster to be ready..."
    oc wait --for=condition=ready elasticsearch -n ${NAMESPACE} --timeout=600s
    
    # Check pods
    print_status "Checking pods..."
    oc get pods -n ${NAMESPACE}
    
    # Check services
    print_status "Checking services..."
    oc get services -n ${NAMESPACE}
    
    # Check routes if enabled
    if oc get routes -n ${NAMESPACE} &> /dev/null; then
        print_status "Checking routes..."
        oc get routes -n ${NAMESPACE}
    fi
    
    print_success "Installation verification completed"
}

# Function to show post-installation information
show_post_install_info() {
    print_status "Installation completed successfully!"
    echo ""
    echo "📋 Next steps:"
    echo "1. Check the cluster status:"
    echo "   oc get elasticsearch -n ${NAMESPACE}"
    echo ""
    echo "2. Get the elastic user password:"
    echo "   oc get secret ${RELEASE_NAME}-es-elastic-user -n ${NAMESPACE} -o jsonpath='{.data.elastic}' | base64 -d"
    echo ""
    echo "3. Test the connection:"
    echo "   oc exec -n ${NAMESPACE} -c elasticsearch \$(oc get pods -n ${NAMESPACE} -l cluster-name=${RELEASE_NAME} -o jsonpath='{.items[0].metadata.name}') -- curl -k -u kubeadmin:\$(oc get secret ${RELEASE_NAME}-es-elastic-user -n ${NAMESPACE} -o jsonpath='{.data.elastic}' | base64 -d) https://localhost:9200"
    echo ""
    echo "4. Access ElasticVue (if enabled):"
    echo "   oc get routes -n ${NAMESPACE}"
    echo ""
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -r|--release-name)
            RELEASE_NAME="$2"
            shift 2
            ;;
        -n|--namespace)
            NAMESPACE="$2"
            shift 2
            ;;
        -f|--values)
            VALUES_FILE="$2"
            shift 2
            ;;
        -o|--operator-version)
            OPERATOR_VERSION="$2"
            shift 2
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Main installation process
main() {
    echo "🚀 Elasticsearch OpenShift Helm Chart Installation"
    echo "=================================================="
    echo ""
    
    check_prerequisites
    check_operator
    install_chart
    verify_installation
    show_post_install_info
}

# Run main function
main 
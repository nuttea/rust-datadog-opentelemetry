#!/bin/bash
set -e

# Load environment variables from .env file if it exists
if [ -f .env ]; then
    echo "Loading environment variables from .env file..."
    export $(grep -v '^#' .env | xargs)
fi

# Configuration (can be overridden by .env file)
CLUSTER_NAME="${CLUSTER_NAME:-nuttee-cluster-1}"
CLUSTER_REGION="${CLUSTER_REGION:-asia-southeast1-b}"
NAMESPACE="${NAMESPACE:-rust-test}"

echo "Deploying Rust Datadog OpenTelemetry Demo to GKE..."
echo "  Cluster: ${CLUSTER_NAME}"
echo "  Region: ${CLUSTER_REGION}"
echo "  Namespace: ${NAMESPACE}"

# Get cluster credentials
echo "Getting cluster credentials..."
gcloud container clusters get-credentials ${CLUSTER_NAME} --region=${CLUSTER_REGION}

# Create namespace if it doesn't exist
echo "Creating namespace..."
kubectl apply -f k8s/namespace.yaml

# Apply Kubernetes manifests
echo "Applying Kubernetes manifests..."
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml

# Wait for deployment to be ready
echo "Waiting for deployment to be ready..."
kubectl rollout status deployment/rust-datadog-otel -n ${NAMESPACE} --timeout=5m

# Get service information
echo ""
echo "✅ Deployment successful!"
echo ""
echo "Service information:"
kubectl get service rust-datadog-otel -n ${NAMESPACE}

echo ""
echo "Pods:"
kubectl get pods -n ${NAMESPACE} -l app=rust-datadog-otel

echo ""
echo "=========================================="
echo "  🚀 Next Steps - Testing the API"
echo "=========================================="
echo ""
echo "1. Start port forwarding (in a new terminal):"
echo "   ./scripts/port-forward.sh"
echo ""
echo "   Or manually:"
echo "   kubectl port-forward -n ${NAMESPACE} svc/rust-datadog-otel 8080:80"
echo ""
echo "2. Test the API:"
echo "   ./scripts/test-api.sh http://localhost:8080"
echo ""
echo "3. View logs:"
echo "   kubectl logs -n ${NAMESPACE} -l app=rust-datadog-otel -f"
echo ""
echo "=========================================="


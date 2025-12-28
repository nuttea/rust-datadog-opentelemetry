#!/bin/bash
set -e

# Load environment variables from .env file if it exists
if [ -f .env ]; then
    echo "Loading environment variables from .env file..."
    export $(grep -v '^#' .env | xargs)
else
    echo "Error: .env file not found!"
    echo "Please create a .env file based on .env.example"
    exit 1
fi

# Configuration
CLUSTER_NAME="${CLUSTER_NAME:-nuttee-cluster-1}"
CLUSTER_REGION="${CLUSTER_REGION:-asia-southeast1-b}"
NAMESPACE="${NAMESPACE:-rust-test}"

echo "=========================================="
echo "  Creating Kubernetes Secrets"
echo "=========================================="
echo ""
echo "  Cluster: ${CLUSTER_NAME}"
echo "  Region: ${CLUSTER_REGION}"
echo "  Namespace: ${NAMESPACE}"
echo ""

# Get cluster credentials
echo "Getting cluster credentials..."
gcloud container clusters get-credentials ${CLUSTER_NAME} --region=${CLUSTER_REGION}

# Create namespace if it doesn't exist
echo "Ensuring namespace exists..."
kubectl create namespace ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

# Check if required variables are set
if [ -z "$DD_API_KEY" ]; then
    echo "Error: DD_API_KEY not set in .env file"
    exit 1
fi

if [ -z "$DD_APP_KEY" ]; then
    echo "Warning: DD_APP_KEY not set in .env file"
fi

# Create or update Datadog secret in rust-test namespace
echo "Creating/updating Datadog secret in ${NAMESPACE} namespace..."
kubectl create secret generic datadog-secret \
    --from-literal=api-key="${DD_API_KEY}" \
    --from-literal=app-key="${DD_APP_KEY:-}" \
    --namespace=${NAMESPACE} \
    --dry-run=client -o yaml | kubectl apply -f -

echo ""
echo "✅ Secrets created successfully!"
echo ""
echo "Verify secrets:"
echo "  kubectl get secrets -n ${NAMESPACE}"
echo ""
echo "View secret details (without values):"
echo "  kubectl describe secret datadog-secret -n ${NAMESPACE}"


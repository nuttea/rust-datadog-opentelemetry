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

echo "Updating Datadog Agent to enable OTLP support..."
echo "  Cluster: ${CLUSTER_NAME}"

# Get cluster credentials
echo "Getting cluster credentials..."
gcloud container clusters get-credentials ${CLUSTER_NAME} --region=${CLUSTER_REGION}

# Check if Datadog Agent is installed
if ! helm list -n datadog | grep -q datadog-agent; then
    echo "❌ Datadog Agent not found in namespace 'datadog'"
    echo "Please install Datadog Agent first."
    exit 1
fi

# Upgrade Datadog Agent with new configuration
echo "Upgrading Datadog Agent with OTLP support..."
helm upgrade datadog-agent \
    -f datadog/datadog-values.yaml \
    --set datadog.clusterName=${CLUSTER_NAME} \
    -n datadog \
    datadog/datadog

echo ""
echo "✅ Datadog Agent upgrade initiated!"
echo ""
echo "Monitor the rollout:"
echo "  kubectl rollout status daemonset/datadog-agent -n datadog"
echo ""
echo "Verify OTLP ports are open:"
echo "  kubectl get daemonset datadog-agent -n datadog -o yaml | grep -A 5 'containerPort: 4317'"
echo ""
echo "Check agent logs:"
echo "  kubectl logs -n datadog -l app=datadog-agent --tail=50"


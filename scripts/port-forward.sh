#!/bin/bash
set -e

# Load environment variables from .env file if it exists
if [ -f .env ]; then
    echo "Loading environment variables from .env file..."
    export $(grep -v '^#' .env | xargs)
fi

# Configuration (can be overridden by .env file)
NAMESPACE="${NAMESPACE:-rust-test}"
SERVICE_NAME="${SERVICE_NAME:-rust-datadog-otel}"
LOCAL_PORT="${LOCAL_PORT:-8080}"
SERVICE_PORT="${SERVICE_PORT:-80}"

echo "=========================================="
echo "  Port Forward to Rust Datadog OTEL"
echo "=========================================="
echo ""
echo "  Namespace: ${NAMESPACE}"
echo "  Service: ${SERVICE_NAME}"
echo "  Local Port: ${LOCAL_PORT}"
echo "  Service Port: ${SERVICE_PORT}"
echo ""

# Check if service exists
echo "Checking if service exists..."
if ! kubectl get service ${SERVICE_NAME} -n ${NAMESPACE} &>/dev/null; then
    echo "❌ Service '${SERVICE_NAME}' not found in namespace '${NAMESPACE}'"
    echo ""
    echo "Available services:"
    kubectl get services -n ${NAMESPACE}
    exit 1
fi

echo "✅ Service found!"
echo ""

# Check if pods are running
echo "Checking pod status..."
POD_COUNT=$(kubectl get pods -n ${NAMESPACE} -l app=rust-datadog-otel --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l | tr -d ' ')

if [ "$POD_COUNT" -eq "0" ]; then
    echo "❌ No running pods found for app=rust-datadog-otel"
    echo ""
    echo "Pod status:"
    kubectl get pods -n ${NAMESPACE} -l app=rust-datadog-otel
    exit 1
fi

echo "✅ Found ${POD_COUNT} running pod(s)"
echo ""

# Start port forwarding
echo "Starting port forward..."
echo "  Local:  http://localhost:${LOCAL_PORT}"
echo "  Remote: ${SERVICE_NAME}:${SERVICE_PORT} (namespace: ${NAMESPACE})"
echo ""
echo "Press Ctrl+C to stop port forwarding"
echo ""
echo "=========================================="
echo ""

# Trap Ctrl+C to cleanup
trap 'echo ""; echo "Port forwarding stopped."; exit 0' INT

# Start port forwarding
kubectl port-forward -n ${NAMESPACE} svc/${SERVICE_NAME} ${LOCAL_PORT}:${SERVICE_PORT}


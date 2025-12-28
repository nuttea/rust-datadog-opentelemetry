#!/bin/bash

# Local development script
# Assumes Datadog Agent is running locally or accessible

echo "Running Rust Datadog OpenTelemetry Demo locally..."
echo ""

# Load environment variables from .env file if it exists
if [ -f .env ]; then
    echo "Loading environment variables from .env file..."
    export $(grep -v '^#' .env | xargs)
    echo "✅ Environment variables loaded from .env"
    echo ""
fi

# Set environment variables for local development
# Using Datadog APM environment variables (datadog-opentelemetry SDK)
# Reference: https://docs.datadoghq.com/tracing/trace_collection/custom_instrumentation/rust
export DD_SERVICE="${DD_SERVICE:-rust-datadog-otel}"
export DD_VERSION="${DD_VERSION:-0.1.0}"
export DD_ENV="${DD_ENV:-local}"
export DD_AGENT_HOST="${DD_AGENT_HOST:-localhost}"
export DD_AGENT_PORT="${DD_AGENT_PORT:-8126}"
export DD_TRACE_ENABLED="${DD_TRACE_ENABLED:-true}"
export DD_LOGS_INJECTION="${DD_LOGS_INJECTION:-true}"
export DD_TRACE_SAMPLE_RATE="${DD_TRACE_SAMPLE_RATE:-1.0}"
export RUST_LOG="${RUST_LOG:-info,rust_datadog_otel=debug}"

echo "Environment configured:"
echo "  Service: ${DD_SERVICE}"
echo "  Version: ${DD_VERSION}"
echo "  Environment: ${DD_ENV}"
echo "  Agent Host: ${DD_AGENT_HOST}"
echo "  Agent Port: ${DD_AGENT_PORT}"
echo "  Trace Enabled: ${DD_TRACE_ENABLED}"
echo "  Sample Rate: ${DD_TRACE_SAMPLE_RATE}"
echo "  Using: Datadog APM (datadog-opentelemetry SDK)"
echo ""

# Check if Datadog Agent is accessible
if ! nc -z ${DD_AGENT_HOST} ${DD_AGENT_PORT} 2>/dev/null; then
    echo "⚠️  Warning: Cannot connect to Datadog Agent on ${DD_AGENT_HOST}:${DD_AGENT_PORT}"
    echo "   Make sure Datadog Agent is running"
    echo "   Or update DD_AGENT_HOST and DD_AGENT_PORT in .env file"
    echo ""
else
    echo "✅ Datadog Agent is accessible at ${DD_AGENT_HOST}:${DD_AGENT_PORT}"
    echo ""
fi

# Build and run
echo "Building application..."
cargo build

echo ""
echo "Starting application..."
cargo run


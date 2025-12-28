#!/bin/bash
set -e

# Load environment variables from .env file if it exists
if [ -f .env ]; then
    echo "Loading environment variables from .env file..."
    export $(grep -v '^#' .env | xargs)
fi

# Configuration (can be overridden by .env file)
PROJECT_ID="${PROJECT_ID:-datadog-gcp-project-id}"
IMAGE_NAME="${IMAGE_NAME:-rust-datadog-otel}"
REGION="${REGION:-asia-southeast1}"

# Get version from Cargo.toml or use git commit hash
VERSION=$(grep '^version' Cargo.toml | head -1 | cut -d'"' -f2)
GIT_HASH=$(git rev-parse --short HEAD 2>/dev/null || echo "dev")
IMAGE_TAG="${VERSION}-${GIT_HASH}"

# Detect host architecture
HOST_ARCH=$(uname -m)
if [ "$HOST_ARCH" = "arm64" ] || [ "$HOST_ARCH" = "aarch64" ]; then
    echo "⚠️  Apple Silicon (ARM64) detected"
    echo "   Building for linux/amd64 (x86_64) platform"
    PLATFORM_FLAG="--platform linux/amd64"
    BUILD_CMD="docker buildx build"
else
    echo "ℹ️  x86_64 architecture detected"
    PLATFORM_FLAG=""
    BUILD_CMD="docker build"
fi

echo "Building and pushing Docker image..."
echo "  Project: ${PROJECT_ID}"
echo "  Image: ${IMAGE_NAME}"
echo "  Tag: ${IMAGE_TAG}"
echo "  Target Platform: linux/amd64 (x86_64)"
echo "  Host Architecture: ${HOST_ARCH}"

# Configure Docker to use gcloud as a credential helper
gcloud auth configure-docker gcr.io

# Ensure buildx is available for cross-platform builds
if [ "$HOST_ARCH" = "arm64" ] || [ "$HOST_ARCH" = "aarch64" ]; then
    echo "Setting up Docker buildx for cross-platform build..."
    docker buildx create --use --name multiarch-builder 2>/dev/null || docker buildx use multiarch-builder || true
fi

# Build the Docker image
echo "Building Docker image..."
${BUILD_CMD} ${PLATFORM_FLAG} -t "gcr.io/${PROJECT_ID}/${IMAGE_NAME}:${IMAGE_TAG}" --load .
docker tag "gcr.io/${PROJECT_ID}/${IMAGE_NAME}:${IMAGE_TAG}" "gcr.io/${PROJECT_ID}/${IMAGE_NAME}:latest"

# Push the Docker image
echo "Pushing Docker image..."
docker push "gcr.io/${PROJECT_ID}/${IMAGE_NAME}:${IMAGE_TAG}"
docker push "gcr.io/${PROJECT_ID}/${IMAGE_NAME}:latest"

echo "✅ Image pushed successfully!"
echo "  gcr.io/${PROJECT_ID}/${IMAGE_NAME}:${IMAGE_TAG}"
echo "  gcr.io/${PROJECT_ID}/${IMAGE_NAME}:latest"


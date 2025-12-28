# Building on Apple Silicon (M1/M2/M3)

## Overview

This guide covers building Docker images on Apple Silicon Macs (ARM64 architecture) for deployment to x86_64 (AMD64) cloud environments.

## The Challenge

- **Apple Silicon Macs** use ARM64 architecture
- **Most cloud environments** (GKE, EKS, etc.) run on x86_64/AMD64
- **Docker images** must match the target platform architecture

## Solution

The `build-and-push.sh` script automatically detects your architecture and builds for the correct platform.

## Automatic Cross-Platform Build

### What the Script Does

```bash
./scripts/build-and-push.sh
```

When running on Apple Silicon, the script:

1. ✅ **Detects** your ARM64 architecture
2. ✅ **Uses** Docker buildx for cross-platform building
3. ✅ **Builds** for `linux/amd64` (x86_64) platform
4. ✅ **Tags** and pushes the image to GCR

### Expected Output

```
⚠️  Apple Silicon (ARM64) detected
   Building for linux/amd64 (x86_64) platform

Building and pushing Docker image...
  Project: your-project-id
  Image: rust-datadog-otel
  Tag: 0.1.0-abc1234
  Target Platform: linux/amd64 (x86_64)
  Host Architecture: arm64

Setting up Docker buildx for cross-platform build...
Building Docker image...
```

## Manual Build (Alternative)

If you prefer to build manually:

### Using Docker Buildx

```bash
# Create buildx builder (one-time setup)
docker buildx create --name multiarch-builder --use

# Build for x86_64
docker buildx build \
  --platform linux/amd64 \
  -t gcr.io/YOUR_PROJECT/rust-datadog-otel:latest \
  --load \
  .

# Push to registry
docker push gcr.io/YOUR_PROJECT/rust-datadog-otel:latest
```

### Using Standard Docker

```bash
# Build with platform flag
docker build \
  --platform linux/amd64 \
  -t gcr.io/YOUR_PROJECT/rust-datadog-otel:latest \
  .
```

## Prerequisites

### 1. Docker Desktop

Ensure you have Docker Desktop for Mac with buildx support:

```bash
# Check Docker version (should be 19.03+)
docker --version

# Check buildx is available
docker buildx version
```

### 2. Rosetta 2 (Optional but Recommended)

For better performance, install Rosetta 2:

```bash
softwareupdate --install-rosetta
```

### 3. Enable Experimental Features

In Docker Desktop preferences:
1. Go to **Docker Engine**
2. Ensure `experimental: true` is set
3. Restart Docker

```json
{
  "experimental": true,
  "builder": {
    "gc": {
      "enabled": true
    }
  }
}
```

## Build Performance

### Expected Build Times

On Apple Silicon (M1/M2/M3):

| Build Type | Time (First Build) | Time (Cached) |
|------------|-------------------|---------------|
| **Native ARM64** | ~2-3 minutes | ~30 seconds |
| **Cross-compile x86_64** | ~5-8 minutes | ~1-2 minutes |

### Optimization Tips

**1. Use BuildKit**
```bash
export DOCKER_BUILDKIT=1
```

**2. Enable Build Cache**
```bash
# Already enabled in the script
docker buildx build --cache-from type=local,src=/tmp/.buildx-cache
```

**3. Use Multi-stage Builds**
- Already implemented in `Dockerfile`
- Separates build and runtime stages
- Reduces final image size

## Troubleshooting

### Error: "buildx: command not found"

**Solution**: Update Docker Desktop to latest version

```bash
# Check version
docker --version  # Should be 19.03+

# Update Docker Desktop from:
# Applications → Docker → Check for Updates
```

### Error: "multiple platforms feature is currently not supported"

**Solution**: Use buildx instead of standard build

```bash
# The script already handles this
./scripts/build-and-push.sh
```

### Error: Build is very slow

**Cause**: Cross-compilation from ARM64 to x86_64 uses QEMU emulation

**Solutions**:
1. **Use cloud build** (recommended for CI/CD):
   ```bash
   gcloud builds submit --tag gcr.io/PROJECT/rust-datadog-otel
   ```

2. **Build on x86_64 machine** (GitHub Actions, etc.)

3. **Accept slower build time** on Apple Silicon (still faster than most CI)

### Warning: "WARNING: The requested image's platform does not match"

This is **normal and expected** when running x86_64 images on ARM64:

```bash
# Expected warning when running locally
docker run gcr.io/PROJECT/rust-datadog-otel:latest
# WARNING: The requested image's platform (linux/amd64) does not match 
# the detected host platform (linux/arm64/v8)
```

**This is OK because**:
- Docker will use Rosetta/QEMU to run the image
- The image is built correctly for cloud deployment
- Cloud platforms run x86_64 natively (no warning there)

## Verification

### Check Image Architecture

```bash
# Inspect the built image
docker inspect gcr.io/PROJECT/rust-datadog-otel:latest | grep Architecture

# Should show:
"Architecture": "amd64"
```

### Test Locally (Optional)

```bash
# Run on Apple Silicon (will use emulation)
docker run --rm gcr.io/PROJECT/rust-datadog-otel:latest

# You'll see a warning about platform mismatch - this is expected
```

### Verify in Cloud

```bash
# Deploy to Kubernetes
kubectl apply -f k8s/

# Check pod is running
kubectl get pods -n rust-test

# Should run natively without platform warnings
```

## CI/CD Considerations

### GitHub Actions

Use hosted runners (already x86_64):

```yaml
jobs:
  build:
    runs-on: ubuntu-latest  # x86_64, no cross-compilation needed
    steps:
      - uses: actions/checkout@v3
      - name: Build Docker image
        run: docker build -t image:tag .
```

### Google Cloud Build

Cloud Build runs on x86_64:

```bash
# Build in cloud (recommended for production)
gcloud builds submit \
  --config cloudbuild.yaml \
  --substitutions=_IMAGE_TAG=$VERSION
```

### Local Development

For local development on Apple Silicon:

```bash
# Option 1: Build ARM64 for local testing
docker build -t rust-datadog-otel:dev-arm64 .

# Option 2: Use the script (builds x86_64)
./scripts/build-and-push.sh
```

## Best Practices

### ✅ Recommended

1. **Use the build script**: It handles everything automatically
2. **Enable Docker BuildKit**: Better caching and performance
3. **Use Cloud Build for CI**: Faster and consistent
4. **Test locally with emulation**: Catch issues early

### ❌ Not Recommended

1. **Don't build ARM64 for cloud**: Won't work on x86_64 nodes
2. **Don't skip platform flag**: Will default to ARM64
3. **Don't worry about emulation warnings**: Expected behavior

## Architecture Comparison

| Aspect | Apple Silicon (ARM64) | x86_64 (AMD64) |
|--------|----------------------|----------------|
| **Local Mac** | Native | Emulated (slower) |
| **GKE/Cloud** | Not supported | Native |
| **Build Speed** | Faster (native) | Slower (cross-compile) |
| **Runtime Speed** | Slower (emulated) | Faster (native) |
| **Recommended for** | Local dev (ARM64 build) | Cloud deploy (x86_64 build) |

## Summary

- ✅ **Script handles everything**: Just run `./scripts/build-and-push.sh`
- ✅ **Builds for x86_64**: Correct platform for cloud deployment
- ✅ **Auto-detection**: Knows when you're on Apple Silicon
- ✅ **Works on both**: ARM64 and x86_64 hosts
- ✅ **Production ready**: Tested and optimized

## Quick Reference

```bash
# Build and push (auto-detects platform)
./scripts/build-and-push.sh

# Check what will be built
uname -m  # Shows: arm64 (Apple Silicon) or x86_64

# Verify image platform
docker inspect IMAGE | grep Architecture
# Should show: "Architecture": "amd64"

# Deploy to cloud
kubectl apply -f k8s/
```

---

**Questions?** Check the main [README](../../README.md) or [Deployment Guide](DEPLOYMENT.md)


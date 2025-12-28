# Environment Variables Migration Summary

## ✅ Migration Complete!

All scripts have been updated to use environment variables from your `.env` file.

---

## 📝 What Changed

### Files Updated

| File | Changes | Status |
|------|---------|--------|
| `scripts/build-and-push.sh` | ✅ Loads from .env, uses PROJECT_ID, IMAGE_NAME, REGION | Updated |
| `scripts/deploy.sh` | ✅ Loads from .env, uses CLUSTER_NAME, CLUSTER_REGION, NAMESPACE | Updated |
| `scripts/update-datadog-agent.sh` | ✅ Loads from .env, uses CLUSTER_NAME, CLUSTER_REGION | Updated |
| `scripts/create-secrets.sh` | ✅ NEW - Creates K8s secrets from DD_API_KEY, DD_APP_KEY | Created |
| `scripts/setup-env.sh` | ✅ NEW - Helps setup .env file | Created |
| `.env.example` | ✅ Template for new users | Created |
| `.gitignore` | ✅ Enhanced to protect .env files | Updated |
| `ENV_SETUP.md` | ✅ Complete environment setup guide | Created |
| `README.md` | ✅ Added env setup instructions | Updated |

### Environment Variables in Your .env

Your existing `.env` file contains:

```bash
# GCP Configuration
CLUSTER_NAME="nuttee-cluster-1"
CLUSTER_REGION="asia-southeast1-b"
PROJECT_ID="datadog-ese-sandbox"
IMAGE_NAME="rust-datadog-otel"
REGION="asia-southeast1"

# Datadog API Keys
DD_API_KEY="[HIDDEN]"
DD_APP_KEY="[HIDDEN]"

# AI API Keys (Optional)
GEMINI_API_KEY="[HIDDEN]"
OPENAI_API_KEY="[HIDDEN]"
ANTHROPIC_API_KEY="[HIDDEN]"
```

---

## 🚀 How to Use

### All Scripts Now Work Automatically

Simply run scripts as before - they'll automatically load from `.env`:

```bash
# Build and push
./scripts/build-and-push.sh

# Deploy to GKE
./scripts/deploy.sh

# Update Datadog Agent
./scripts/update-datadog-agent.sh

# Create Kubernetes secrets (NEW!)
./scripts/create-secrets.sh
```

### Override Variables if Needed

You can still override variables for specific runs:

```bash
# Use different namespace
NAMESPACE="production" ./scripts/deploy.sh

# Use different project
PROJECT_ID="another-project" ./scripts/build-and-push.sh
```

---

## 🆕 New Features

### 1. Create Kubernetes Secrets Script

New script to create Datadog secrets in Kubernetes from your `.env`:

```bash
./scripts/create-secrets.sh
```

This creates a `datadog-secret` in your namespace with:
- `api-key`: From DD_API_KEY
- `app-key`: From DD_APP_KEY

### 2. Setup Environment Script

Helper script for new team members:

```bash
./scripts/setup-env.sh
```

This copies `.env.example` to `.env` with instructions on what to fill in.

### 3. Environment Setup Documentation

Comprehensive guide: [ENV_SETUP.md](ENV_SETUP.md)

Covers:
- Creating .env file
- Variable reference
- Security best practices
- Troubleshooting

---

## 🔒 Security Improvements

### Enhanced .gitignore

Updated to protect all environment files:

```gitignore
# Never commit these!
.env
.env.local
.env.*.local
*.env

# But allow the example
!.env.example
```

### Safe Sharing

Created `.env.example` with placeholder values:
- Safe to commit to git
- Shows required variables
- No sensitive data

---

## 📊 Script Behavior

### Before (Hardcoded)

```bash
# Scripts had hardcoded values
PROJECT_ID="datadog-ese-sandbox"
CLUSTER_NAME="nuttee-cluster-1"

# Had to edit scripts to change values
```

### After (Environment Variables)

```bash
# Scripts load from .env automatically
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

# Falls back to defaults if .env doesn't exist
PROJECT_ID="${PROJECT_ID:-datadog-ese-sandbox}"
```

**Benefits:**
- ✅ No need to edit scripts
- ✅ Easy to switch environments
- ✅ Secrets stay out of git
- ✅ Backwards compatible (defaults work)

---

## 🧪 Testing Your Setup

### 1. Verify .env is Loaded

```bash
# Check what scripts will use
source .env
echo "Cluster: $CLUSTER_NAME"
echo "Region: $CLUSTER_REGION"
echo "Project: $PROJECT_ID"
```

### 2. Test Each Script

```bash
# Test build script (dry run)
echo "Testing build configuration..."
./scripts/build-and-push.sh --help 2>/dev/null || echo "Script will use: PROJECT_ID=$PROJECT_ID"

# Test deploy script (dry run)
echo "Testing deploy configuration..."
head -20 scripts/deploy.sh | grep -A 5 "Load environment"
```

### 3. Create Kubernetes Secrets

```bash
# Create secrets from your .env
./scripts/create-secrets.sh

# Verify secrets were created
kubectl get secrets -n rust-test
```

---

## 📋 Variable Mapping

| Script | Variables Used | Source |
|--------|---------------|--------|
| `build-and-push.sh` | PROJECT_ID, IMAGE_NAME, REGION | .env |
| `deploy.sh` | CLUSTER_NAME, CLUSTER_REGION, NAMESPACE | .env |
| `update-datadog-agent.sh` | CLUSTER_NAME, CLUSTER_REGION | .env |
| `create-secrets.sh` | CLUSTER_NAME, CLUSTER_REGION, NAMESPACE, DD_API_KEY, DD_APP_KEY | .env |
| `local-run.sh` | (Uses standard OTel env vars) | Set manually or .env |

---

## 🔄 Backwards Compatibility

### Still Works Without .env

All scripts have default values, so they work even without a `.env` file:

```bash
# These defaults are used if .env doesn't exist
CLUSTER_NAME="${CLUSTER_NAME:-nuttee-cluster-1}"
CLUSTER_REGION="${CLUSTER_REGION:-asia-southeast1-b}"
PROJECT_ID="${PROJECT_ID:-datadog-ese-sandbox}"
```

### Migration Path

1. **Current users**: No action needed! Your `.env` is already being used
2. **New users**: Run `./scripts/setup-env.sh` to create `.env`
3. **CI/CD**: Set env vars in pipeline, or mount `.env` as secret

---

## 🎯 Next Steps

### 1. Share .env.example with Team

```bash
# Team members can copy and customize
cp .env.example .env
# Edit with their own values
```

### 2. Setup CI/CD Pipeline

Configure your CI/CD to use environment variables:

**GitHub Actions:**
```yaml
env:
  CLUSTER_NAME: ${{ secrets.CLUSTER_NAME }}
  PROJECT_ID: ${{ secrets.PROJECT_ID }}
  DD_API_KEY: ${{ secrets.DD_API_KEY }}
```

**GitLab CI:**
```yaml
variables:
  CLUSTER_NAME: "nuttee-cluster-1"
  PROJECT_ID: "datadog-ese-sandbox"
```

### 3. Document for Your Team

Point team members to:
- [ENV_SETUP.md](ENV_SETUP.md) - Setup guide
- `.env.example` - Template file
- This document - Migration info

---

## ❓ Troubleshooting

### Scripts Don't See .env Variables

```bash
# Make sure you're in project root
pwd
# Should show: /path/to/rust-datadog-opentelemetry

# Check .env exists
ls -la .env

# Check .env format (no spaces around =)
cat .env | head -5
```

### Variables Not Being Used

```bash
# Debug script loading
bash -x ./scripts/deploy.sh 2>&1 | grep "Loading environment"
bash -x ./scripts/deploy.sh 2>&1 | grep CLUSTER_NAME
```

### Secrets Creation Fails

```bash
# Check DD_API_KEY is set
source .env
echo "DD_API_KEY length: ${#DD_API_KEY}"
# Should show a number > 0

# Check kubectl access
kubectl get namespaces
```

---

## 📚 Additional Resources

- **Environment Setup**: [ENV_SETUP.md](ENV_SETUP.md)
- **Deployment Guide**: [DEPLOYMENT.md](DEPLOYMENT.md)
- **Main Documentation**: [README.md](README.md)
- **Security Guide**: [SECURITY.md](SECURITY.md)

---

## ✨ Summary

| Feature | Status | Notes |
|---------|--------|-------|
| Scripts use .env | ✅ Done | All 5 scripts updated |
| .env.example created | ✅ Done | Safe to share template |
| Create secrets script | ✅ Done | NEW: ./scripts/create-secrets.sh |
| Setup helper script | ✅ Done | NEW: ./scripts/setup-env.sh |
| Documentation | ✅ Done | ENV_SETUP.md created |
| Security enhanced | ✅ Done | .gitignore updated |
| Backwards compatible | ✅ Done | Defaults still work |

**Status**: ✅ **Migration Complete**  
**Your .env is being used by all scripts!**  
**No action required - everything works as before, but better!**

---

**Created**: December 28, 2025  
**Migration Date**: December 28, 2025  
**Status**: ✅ Complete


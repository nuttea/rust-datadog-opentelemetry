# Environment Variables Setup Guide

This project uses environment variables for configuration. All scripts now support loading variables from a `.env` file.

## 🚀 Quick Setup

### 1. Create Your .env File

```bash
# Option 1: Use the setup script
./scripts/setup-env.sh

# Option 2: Manually copy the example
cp .env.example .env
```

### 2. Edit .env File

Open `.env` and update with your values:

```bash
# Edit with your preferred editor
vim .env
# or
code .env
# or
nano .env
```

### 3. Verify Configuration

```bash
# Check your environment variables
cat .env

# Test that scripts can load it
./scripts/build-and-push.sh --help
```

## 📋 Environment Variables Reference

### GCP Configuration (Required for Deployment)

| Variable | Description | Example |
|----------|-------------|---------|
| `CLUSTER_NAME` | GKE cluster name | `nuttee-cluster-1` |
| `CLUSTER_REGION` | GKE cluster region | `asia-southeast1-b` |
| `PROJECT_ID` | GCP project ID | `datadog-ese-sandbox` |
| `IMAGE_NAME` | Docker image name | `rust-datadog-otel` |
| `REGION` | GCP region | `asia-southeast1` |
| `NAMESPACE` | Kubernetes namespace | `rust-test` |

### Datadog Configuration (Required)

| Variable | Description | Where to Get |
|----------|-------------|--------------|
| `DD_API_KEY` | Datadog API key | [API Keys](https://app.datadoghq.com/organization-settings/api-keys) |
| `DD_APP_KEY` | Datadog Application key | [App Keys](https://app.datadoghq.com/organization-settings/application-keys) |

### Datadog APM Configuration (for local development)

| Variable | Description | Default | Example |
|----------|-------------|---------|---------|
| `DD_SERVICE` | Service name | `rust-datadog-otel` | Your service name |
| `DD_VERSION` | Service version | `0.1.0` | Your version |
| `DD_ENV` | Environment | `local` | `development`, `staging`, `production` |
| `DD_AGENT_HOST` | Datadog Agent hostname | `localhost` | `datadog-agent.local` |
| `DD_AGENT_PORT` | Datadog Agent APM port | `8126` | `8126` |
| `DD_TRACE_ENABLED` | Enable tracing | `true` | `true` / `false` |
| `DD_LOGS_INJECTION` | Inject trace IDs in logs | `true` | `true` / `false` |
| `DD_TRACE_SAMPLE_RATE` | Sampling rate | `1.0` | `0.0` - `1.0` |

### AI API Keys (Optional)

| Variable | Description | Purpose |
|----------|-------------|---------|
| `GEMINI_API_KEY` | Google Gemini API key | Future AI integrations |
| `OPENAI_API_KEY` | OpenAI API key | Future AI integrations |
| `ANTHROPIC_API_KEY` | Anthropic Claude API key | Future AI integrations |

## 🔧 How Scripts Use Environment Variables

All deployment scripts now automatically load variables from `.env`:

### build-and-push.sh
```bash
# Loads from .env automatically
./scripts/build-and-push.sh

# Or override specific variables
PROJECT_ID="my-project" ./scripts/build-and-push.sh
```

### deploy.sh
```bash
# Loads from .env automatically
./scripts/deploy.sh

# Or override
NAMESPACE="production" ./scripts/deploy.sh
```

### update-datadog-agent.sh
```bash
# Loads from .env automatically
./scripts/update-datadog-agent.sh
```

### create-secrets.sh (New!)
```bash
# Creates Kubernetes secrets from .env
./scripts/create-secrets.sh
```

## 📦 Scripts Updated

All these scripts now support `.env` file:

- ✅ `scripts/build-and-push.sh` - Uses PROJECT_ID, IMAGE_NAME, REGION
- ✅ `scripts/deploy.sh` - Uses CLUSTER_NAME, CLUSTER_REGION, NAMESPACE
- ✅ `scripts/update-datadog-agent.sh` - Uses CLUSTER_NAME, CLUSTER_REGION
- ✅ `scripts/create-secrets.sh` - Uses DD_API_KEY, DD_APP_KEY (NEW!)
- ✅ `scripts/setup-env.sh` - Helps create .env file (NEW!)

## 🔒 Security Best Practices

### DO ✅

1. **Keep .env file local**
   ```bash
   # Already in .gitignore
   .env
   ```

2. **Use different .env files per environment**
   ```bash
   .env.development
   .env.staging
   .env.production
   ```

3. **Rotate API keys regularly**
   - Update in Datadog dashboard
   - Update in .env
   - Run `./scripts/create-secrets.sh` to update K8s secrets

4. **Verify .env is not in git**
   ```bash
   git status --ignored | grep .env
   # Should show: .env (ignored)
   ```

### DON'T ❌

1. **Never commit .env to git**
   ```bash
   # This would expose your secrets!
   git add .env  # ❌ DON'T DO THIS
   ```

2. **Never share .env file**
   - Don't email it
   - Don't put in Slack/chat
   - Don't screenshot it

3. **Don't use production keys in development**
   - Use separate keys for dev/staging/prod

## 🔐 Managing Secrets

### Creating Kubernetes Secrets

Use the new script to create secrets from your .env:

```bash
# Create secrets in rust-test namespace
./scripts/create-secrets.sh

# Create secrets in different namespace
NAMESPACE="production" ./scripts/create-secrets.sh
```

### Verifying Secrets

```bash
# List secrets
kubectl get secrets -n rust-test

# View secret details (without values)
kubectl describe secret datadog-secret -n rust-test

# View secret values (be careful!)
kubectl get secret datadog-secret -n rust-test -o yaml
```

### Updating Secrets

When you rotate API keys:

1. Update `.env` file with new keys
2. Run `./scripts/create-secrets.sh`
3. Restart pods to use new secrets:
   ```bash
   kubectl rollout restart deployment/rust-datadog-otel -n rust-test
   ```

## 📝 Example .env File

```bash
# GCP Configuration
CLUSTER_NAME="nuttee-cluster-1"
CLUSTER_REGION="asia-southeast1-b"
PROJECT_ID="datadog-ese-sandbox"
IMAGE_NAME="rust-datadog-otel"
REGION="asia-southeast1"
NAMESPACE="rust-test"

# Datadog API Keys
DD_API_KEY="your_actual_api_key_here"
DD_APP_KEY="your_actual_app_key_here"

# Optional: AI API Keys
GEMINI_API_KEY="your_gemini_key_here"
OPENAI_API_KEY="your_openai_key_here"
ANTHROPIC_API_KEY="your_anthropic_key_here"
```

## 🧪 Testing Configuration

### Test Environment Loading

```bash
# Test that .env is loaded correctly
source .env
echo "Cluster: $CLUSTER_NAME"
echo "Region: $CLUSTER_REGION"
echo "Project: $PROJECT_ID"
```

### Test Script Configuration

```bash
# Dry run - check what would be deployed
echo "Testing build-and-push configuration..."
grep "PROJECT_ID=" scripts/build-and-push.sh

echo "Testing deploy configuration..."
grep "CLUSTER_NAME=" scripts/deploy.sh
```

## 🔄 Migration from Hardcoded Values

If you were using the old scripts with hardcoded values:

1. **No action required!** Scripts still work with defaults
2. **Optional**: Create `.env` for easier management
3. **Benefit**: Override any value without editing scripts

### Before (Hardcoded)
```bash
# Had to edit script file
vim scripts/deploy.sh
# Change CLUSTER_NAME="old-cluster"
# to CLUSTER_NAME="new-cluster"
```

### After (Environment Variables)
```bash
# Just update .env
vim .env
# Update CLUSTER_NAME="new-cluster"
```

## 📚 Additional Resources

### Getting Datadog API Keys

1. **API Key**:
   - Login to [Datadog](https://app.datadoghq.com)
   - Go to Organization Settings > API Keys
   - Create or copy existing API key

2. **Application Key**:
   - Go to Organization Settings > Application Keys
   - Create new application key with appropriate permissions

### Environment Variable Precedence

Scripts use this order (highest to lowest priority):

1. Command-line override: `PROJECT_ID="custom" ./script.sh`
2. Environment variable: `export PROJECT_ID="custom"`
3. .env file: `PROJECT_ID="custom"` in .env
4. Default value: `PROJECT_ID="${PROJECT_ID:-default}"`

## ❓ Troubleshooting

### .env Not Loading

```bash
# Check if .env file exists
ls -la .env

# Check file permissions
chmod 600 .env

# Verify no BOM or special characters
file .env
```

### Scripts Not Finding .env

```bash
# Make sure you're in project root
pwd
# Should show: /path/to/rust-datadog-opentelemetry

# Run scripts from project root
./scripts/deploy.sh
# NOT: cd scripts && ./deploy.sh
```

### Variables Not Being Used

```bash
# Debug what script sees
bash -x ./scripts/deploy.sh 2>&1 | grep CLUSTER_NAME
```

## 🆘 Getting Help

If you have issues with environment setup:

1. Check this documentation
2. Verify .env file format (no spaces around `=`)
3. Ensure no quotes within quotes
4. Check script output for error messages

---

**Created**: December 28, 2025  
**Last Updated**: December 28, 2025  
**Status**: ✅ All scripts updated to support .env


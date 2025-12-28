#!/bin/bash
set -e

# Environment Setup Script
# This script helps create a .env file from the example template

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "╔═══════════════════════════════════════════════════════════════════════╗"
echo "║                   🔧 Environment Setup                                ║"
echo "╚═══════════════════════════════════════════════════════════════════════╝"
echo ""

# Check if .env already exists
if [ -f .env ]; then
    echo -e "${YELLOW}⚠️  .env file already exists!${NC}"
    echo ""
    read -p "Do you want to overwrite it? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}Aborting. Keeping existing .env file.${NC}"
        exit 0
    fi
    echo ""
fi

# Check if .env.example exists
if [ ! -f .env.example ]; then
    echo -e "${RED}❌ Error: .env.example not found!${NC}"
    exit 1
fi

# Copy example to .env
cp .env.example .env

echo -e "${GREEN}✅ Created .env file from .env.example${NC}"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${BLUE}📝 Please edit .env file and update the following values:${NC}"
echo ""

echo -e "${YELLOW}1️⃣  GCP/GKE Configuration (REQUIRED for deployment):${NC}"
echo "   └─ PROJECT_ID       : Your GCP project ID"
echo "   └─ CLUSTER_NAME     : Your GKE cluster name (default: nuttee-cluster-1)"
echo "   └─ CLUSTER_REGION   : Your GKE cluster zone (default: asia-southeast1-b)"
echo "   └─ REGION           : Your GCP region (default: asia-southeast1)"
echo ""

echo -e "${YELLOW}2️⃣  Kubernetes Configuration:${NC}"
echo "   └─ NAMESPACE        : K8s namespace (default: rust-test)"
echo "   └─ SERVICE_NAME     : K8s service name (default: rust-datadog-otel)"
echo "   └─ LOCAL_PORT       : Local port for port-forward (default: 8080)"
echo "   └─ SERVICE_PORT     : K8s service port (default: 80)"
echo ""

echo -e "${YELLOW}3️⃣  Datadog Configuration (REQUIRED):${NC}"
echo "   └─ DD_SERVICE       : Service name in Datadog (default: rust-datadog-otel)"
echo "   └─ DD_VERSION       : Application version (default: 0.1.0)"
echo "   └─ DD_ENV           : Environment (local/development/staging/production)"
echo "   └─ DD_AGENT_HOST    : Agent host (default: localhost for local dev)"
echo "   └─ DD_AGENT_PORT    : Agent port (default: 8126)"
echo ""

echo -e "${RED}4️⃣  Datadog API Keys (REQUIRED - SECRETS):${NC}"
echo "   └─ DD_API_KEY       : Get from https://app.datadoghq.com/organization-settings/api-keys"
echo "   └─ DD_APP_KEY       : Get from https://app.datadoghq.com/organization-settings/application-keys"
echo ""

echo -e "${BLUE}5️⃣  AI API Keys (OPTIONAL):${NC}"
echo "   └─ GEMINI_API_KEY   : Google Gemini (if needed)"
echo "   └─ OPENAI_API_KEY   : OpenAI (if needed)"
echo "   └─ ANTHROPIC_API_KEY: Claude (if needed)"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${GREEN}📝 Edit the file now:${NC}"
echo ""
echo "   # Using your preferred editor:"
echo "   vim .env     # or"
echo "   nano .env    # or"
echo "   code .env    # or"
echo "   open .env    # (opens in default editor)"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${GREEN}📚 Next Steps:${NC}"
echo ""
echo "   1. Edit .env with your actual values"
echo "   2. For local development:"
echo "      └─ ./scripts/local-run.sh"
echo ""
echo "   3. For Kubernetes deployment:"
echo "      └─ ./scripts/build-and-push.sh"
echo "      └─ ./scripts/deploy.sh"
echo ""
echo "   4. For testing:"
echo "      └─ ./scripts/port-forward.sh"
echo "      └─ ./scripts/test-api.sh http://localhost:8080"
echo ""
echo "   5. For load generation:"
echo "      └─ ./scripts/load-test.sh http://localhost:8080"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${RED}⚠️  Security Reminders:${NC}"
echo ""
echo "   • .env is in .gitignore - it will NOT be committed"
echo "   • NEVER share .env contents in chat/email/slack"
echo "   • Rotate API keys regularly (every 90 days)"
echo "   • Use different keys for different environments"
echo "   • For K8s, use secrets: ./scripts/create-secrets.sh"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Ask if user wants to edit now
read -p "Open .env in your default editor now? (Y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    # Try to open with various editors
    if command -v code &> /dev/null; then
        code .env
    elif command -v open &> /dev/null; then
        open .env
    elif command -v nano &> /dev/null; then
        nano .env
    elif command -v vim &> /dev/null; then
        vim .env
    else
        echo -e "${YELLOW}Please open .env manually with your preferred editor.${NC}"
    fi
fi

echo ""
echo -e "${GREEN}✅ Setup complete!${NC}"
echo ""


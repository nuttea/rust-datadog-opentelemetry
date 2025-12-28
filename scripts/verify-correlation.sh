#!/bin/bash
set -e

# Trace-Log Correlation Verification Script
# This script helps verify that Datadog is correlating traces and logs correctly

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "╔═══════════════════════════════════════════════════════════════════════╗"
echo "║           🔍 Datadog Trace-Log Correlation Verification              ║"
echo "╚═══════════════════════════════════════════════════════════════════════╝"
echo ""

BASE_URL="${1:-http://localhost:8080}"
NAMESPACE="${2:-rust-test}"

echo -e "${BLUE}Configuration:${NC}"
echo "  Base URL: ${BASE_URL}"
echo "  Namespace: ${NAMESPACE}"
echo ""

# Check if application is reachable
echo -e "${YELLOW}Step 1: Checking if application is reachable...${NC}"
if curl -s "${BASE_URL}/health" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Application is reachable${NC}"
else
    echo -e "${RED}✗ Application is not reachable!${NC}"
    echo "  Make sure to run: ./scripts/port-forward.sh"
    exit 1
fi
echo ""

# Make test request
echo -e "${YELLOW}Step 2: Making test request...${NC}"
TIMESTAMP=$(date +%s)
TEST_EMAIL="correlation-test-${TIMESTAMP}@example.com"

RESPONSE=$(curl -s -X POST "${BASE_URL}/api/users" \
  -H "Content-Type: application/json" \
  -d "{\"name\":\"Correlation Test ${TIMESTAMP}\",\"email\":\"${TEST_EMAIL}\"}")

echo -e "${GREEN}✓ Request sent${NC}"
echo "  Response: ${RESPONSE}"
echo ""

# Check pod logs
echo -e "${YELLOW}Step 3: Checking application logs...${NC}"
echo ""

if kubectl get pods -n "${NAMESPACE}" -l app=rust-datadog-otel > /dev/null 2>&1; then
    echo -e "${BLUE}Recent application logs:${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    LOGS=$(kubectl logs -l app=rust-datadog-otel -n "${NAMESPACE}" --tail=10 2>/dev/null || echo "")
    
    if [ -z "$LOGS" ]; then
        echo -e "${YELLOW}⚠ No logs found. Application might not be running in K8s.${NC}"
    else
        echo "$LOGS" | tail -5
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        
        # Check for trace context in logs
        echo -e "${BLUE}Checking for trace context in logs:${NC}"
        
        if echo "$LOGS" | grep -q "trace_id"; then
            echo -e "${GREEN}✓ Found trace_id in logs${NC}"
            TRACE_ID=$(echo "$LOGS" | grep -o '"trace_id":"[^"]*"' | head -1 || echo "")
            echo "  ${TRACE_ID}"
        else
            echo -e "${YELLOW}⚠ No trace_id found in recent logs${NC}"
        fi
        
        if echo "$LOGS" | grep -q "span_id"; then
            echo -e "${GREEN}✓ Found span_id in logs${NC}"
            SPAN_ID=$(echo "$LOGS" | grep -o '"span_id":"[^"]*"' | head -1 || echo "")
            echo "  ${SPAN_ID}"
        else
            echo -e "${YELLOW}⚠ No span_id found in recent logs${NC}"
        fi
        
        if echo "$LOGS" | grep -q "dd.trace_id"; then
            echo -e "${GREEN}✓ Found dd.trace_id in logs (Datadog format!)${NC}"
        else
            echo -e "${YELLOW}⚠ No dd.trace_id found (may need agent configuration)${NC}"
        fi
    fi
else
    echo -e "${YELLOW}⚠ Not running in Kubernetes. Skipping pod log check.${NC}"
fi
echo ""

# Check Datadog Agent
echo -e "${YELLOW}Step 4: Checking Datadog Agent status...${NC}"
if kubectl get pods -n datadog > /dev/null 2>&1; then
    echo -e "${BLUE}Datadog Agent pods:${NC}"
    kubectl get pods -n datadog 2>/dev/null || echo "No Datadog pods found"
    echo ""
    
    # Check if agent is receiving traces
    echo -e "${BLUE}Checking agent APM status:${NC}"
    if kubectl exec -it deployment/datadog -n datadog -- agent status 2>/dev/null | grep -A 5 "APM Agent" > /dev/null; then
        echo -e "${GREEN}✓ Datadog Agent is running${NC}"
    else
        echo -e "${YELLOW}⚠ Could not verify Datadog Agent status${NC}"
    fi
else
    echo -e "${YELLOW}⚠ No Datadog namespace found${NC}"
fi
echo ""

# Instructions for manual verification
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${GREEN}📋 Manual Verification Steps:${NC}"
echo ""
echo "1. ${BLUE}Check Traces in Datadog:${NC}"
echo "   • Go to: https://app.datadoghq.com/apm/traces"
echo "   • Filter by: service:rust-datadog-otel"
echo "   • Find the POST /api/users request from ~$(date '+%H:%M:%S')"
echo "   • Open the trace details"
echo ""
echo "2. ${BLUE}Look for Logs in Trace:${NC}"
echo "   • In the trace view, look for:"
echo "     - 'Logs' tab or section"
echo "     - Log events in the timeline"
echo "     - Associated log count"
echo ""
echo "3. ${BLUE}Check Logs in Datadog:${NC}"
echo "   • Go to: https://app.datadoghq.com/logs"
echo "   • Filter by: service:rust-datadog-otel @email:${TEST_EMAIL}"
echo "   • Open a log entry"
echo ""
echo "4. ${BLUE}Look for Trace Link in Log:${NC}"
echo "   • In the log details, look for:"
echo "     - 'View Trace' button or link"
echo "     - dd.trace_id attribute"
echo "     - dd.span_id attribute"
echo "   • Click 'View Trace' to navigate to the trace"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${GREEN}✅ What Should Work:${NC}"
echo "   • Logs appear in trace view"
echo "   • 'View Trace' link appears in log view"
echo "   • Both link to each other correctly"
echo ""
echo -e "${RED}❌ If Correlation Doesn't Work:${NC}"
echo "   1. Check if logs have dd.trace_id (decimal format)"
echo "   2. Verify DD_LOGS_INJECTION=true in deployment"
echo "   3. Check Datadog Agent configuration"
echo "   4. Review: docs/guides/TRACE_LOG_CORRELATION.md"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${BLUE}🔗 Quick Links:${NC}"
echo "   Traces: https://app.datadoghq.com/apm/traces?query=service%3Arust-datadog-otel"
echo "   Logs:   https://app.datadoghq.com/logs?query=service%3Arust-datadog-otel"
echo "   Docs:   docs/guides/TRACE_LOG_CORRELATION.md"
echo ""
echo -e "${GREEN}Test Email for Filtering: ${TEST_EMAIL}${NC}"
echo ""


#!/bin/bash
set -e

# Load Test Script - Generates continuous traffic across all API endpoints
# This helps populate Datadog with traces and metrics for testing

# Configuration
BASE_URL="${1:-http://localhost:8080}"
REQUESTS_PER_CYCLE="${2:-5}"
DELAY_BETWEEN_REQUESTS="${3:-1}"
DELAY_BETWEEN_CYCLES="${4:-5}"

echo "🔄 Starting Load Test"
echo "  Base URL: ${BASE_URL}"
echo "  Requests per cycle: ${REQUESTS_PER_CYCLE}"
echo "  Delay between requests: ${DELAY_BETWEEN_REQUESTS}s"
echo "  Delay between cycles: ${DELAY_BETWEEN_CYCLES}s"
echo ""
echo "Press Ctrl+C to stop"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Counter for tracking
CYCLE=0
TOTAL_REQUESTS=0
SUCCESS_COUNT=0
ERROR_COUNT=0

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Trap Ctrl+C to show summary
trap 'echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; echo "📊 Load Test Summary:"; echo "  Total Cycles: $CYCLE"; echo "  Total Requests: $TOTAL_REQUESTS"; echo "  Successful: $SUCCESS_COUNT"; echo "  Failed: $ERROR_COUNT"; exit 0' INT

# Function to make a request and track result
make_request() {
    local METHOD=$1
    local ENDPOINT=$2
    local DATA=$3
    local DESCRIPTION=$4
    
    TOTAL_REQUESTS=$((TOTAL_REQUESTS + 1))
    
    if [ -z "$DATA" ]; then
        RESPONSE=$(curl -s -w "\n%{http_code}" -X "$METHOD" "${BASE_URL}${ENDPOINT}" 2>/dev/null)
    else
        RESPONSE=$(curl -s -w "\n%{http_code}" -X "$METHOD" "${BASE_URL}${ENDPOINT}" \
            -H "Content-Type: application/json" \
            -d "$DATA" 2>/dev/null)
    fi
    
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    
    if [[ "$HTTP_CODE" =~ ^2[0-9][0-9]$ ]]; then
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
        echo -e "${GREEN}✓${NC} ${METHOD} ${ENDPOINT} - ${DESCRIPTION} (${HTTP_CODE})"
    else
        ERROR_COUNT=$((ERROR_COUNT + 1))
        echo -e "${RED}✗${NC} ${METHOD} ${ENDPOINT} - ${DESCRIPTION} (${HTTP_CODE})"
    fi
    
    sleep "$DELAY_BETWEEN_REQUESTS"
}

# Main loop
while true; do
    CYCLE=$((CYCLE + 1))
    echo -e "\n${BLUE}━━━ Cycle ${CYCLE} ━━━${NC}"
    
    for i in $(seq 1 "$REQUESTS_PER_CYCLE"); do
        # Randomly select an operation
        OPERATION=$((RANDOM % 9))
        
        case $OPERATION in
            0)
                # Health check
                make_request "GET" "/health" "" "Health Check"
                ;;
            1)
                # Root endpoint
                make_request "GET" "/" "" "API Info"
                ;;
            2)
                # Create user
                USER_DATA='{"name":"Test User'"$RANDOM"'","email":"test'"$RANDOM"'@example.com"}'
                make_request "POST" "/api/users" "$USER_DATA" "Create User"
                ;;
            3)
                # Get user (random ID)
                USER_ID=$(uuidgen | tr '[:upper:]' '[:lower:]')
                make_request "GET" "/api/users/${USER_ID}" "" "Get User"
                ;;
            4)
                # Create order
                ORDER_DATA='{"user_id":"user-'"$RANDOM"'","items":[{"product_id":"prod-001","quantity":2,"price":29.99}]}'
                make_request "POST" "/api/orders" "$ORDER_DATA" "Create Order"
                ;;
            5)
                # Get order (random ID)
                ORDER_ID=$(uuidgen | tr '[:upper:]' '[:lower:]')
                make_request "GET" "/api/orders/${ORDER_ID}" "" "Get Order"
                ;;
            6)
                # Slow operation
                make_request "GET" "/api/slow-operation" "" "Slow Operation"
                ;;
            7)
                # Database query
                make_request "GET" "/api/database-query" "" "Database Query"
                ;;
            8)
                # Simulate error (random type)
                ERROR_TYPES=("generic" "server" "database" "timeout")
                ERROR_TYPE=${ERROR_TYPES[$((RANDOM % 4))]}
                make_request "GET" "/api/simulate-error?error_type=${ERROR_TYPE}" "" "Simulate ${ERROR_TYPE} Error"
                ;;
        esac
    done
    
    # Show cycle summary
    SUCCESS_RATE=$((SUCCESS_COUNT * 100 / TOTAL_REQUESTS))
    echo -e "${YELLOW}━━━ Cycle ${CYCLE} Complete ━━━${NC}"
    echo -e "  Requests: ${TOTAL_REQUESTS} | Success: ${SUCCESS_COUNT} (${SUCCESS_RATE}%) | Errors: ${ERROR_COUNT}"
    
    # Wait before next cycle
    sleep "$DELAY_BETWEEN_CYCLES"
done


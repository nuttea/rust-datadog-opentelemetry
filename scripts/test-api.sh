#!/bin/bash

# Configuration
if [ -z "$1" ]; then
    echo "Usage: $0 <API_URL>"
    echo "Example: $0 http://localhost:8080"
    echo "Example: $0 http://34.87.123.45"
    exit 1
fi

API_URL=$1

echo "Testing Rust Datadog OpenTelemetry API"
echo "API URL: ${API_URL}"
echo ""

# Test 1: Health check
echo "1. Testing health endpoint..."
curl -s "${API_URL}/health" | jq .
echo ""

# Test 2: Root endpoint
echo "2. Testing root endpoint..."
curl -s "${API_URL}/" | jq .
echo ""

# Test 3: Create user
echo "3. Creating a user..."
USER_RESPONSE=$(curl -s -X POST "${API_URL}/api/users" \
    -H "Content-Type: application/json" \
    -d '{"name": "John Doe", "email": "john@example.com"}')
echo $USER_RESPONSE | jq .
USER_ID=$(echo $USER_RESPONSE | jq -r '.id')
echo ""

# Test 4: Get user
echo "4. Getting user by ID..."
curl -s "${API_URL}/api/users/${USER_ID}" | jq .
echo ""

# Test 5: Create order
echo "5. Creating an order..."
curl -s -X POST "${API_URL}/api/orders" \
    -H "Content-Type: application/json" \
    -d '{
        "user_id": "'${USER_ID}'",
        "items": [
            {"product_id": "prod-001", "quantity": 2, "price": 29.99},
            {"product_id": "prod-002", "quantity": 1, "price": 49.99}
        ]
    }' | jq .
echo ""

# Test 6: Get order
echo "6. Getting order by ID..."
curl -s "${API_URL}/api/orders/order-123" | jq .
echo ""

# Test 7: Slow operation
echo "7. Testing slow operation (will take ~1 second)..."
curl -s "${API_URL}/api/slow-operation" | jq .
echo ""

# Test 8: Database query
echo "8. Testing database query simulation..."
curl -s "${API_URL}/api/database-query" | jq .
echo ""

# Test 9: Error simulation - generic
echo "9. Simulating generic error..."
curl -s "${API_URL}/api/simulate-error" | jq .
echo ""

# Test 10: Error simulation - server error
echo "10. Simulating server error..."
curl -s "${API_URL}/api/simulate-error?error_type=server" | jq .
echo ""

# Test 11: Error simulation - database error
echo "11. Simulating database error..."
curl -s "${API_URL}/api/simulate-error?error_type=database" | jq .
echo ""

echo "✅ All tests completed!"
echo ""
echo "Check Datadog for:"
echo "  - Traces: APM > Traces (service: rust-datadog-otel)"
echo "  - Logs: Logs > Search (service:rust-datadog-otel)"
echo "  - Service Map: APM > Service Map"
echo "  - Metrics: Metrics Explorer"


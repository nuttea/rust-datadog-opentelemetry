# Port Forward Testing Guide

This guide explains how to access and test the Rust Datadog OpenTelemetry service using kubectl port-forward.

## 🎯 Why Port Forward?

The service uses **ClusterIP** instead of LoadBalancer for:
- ✅ **Security**: No public exposure
- ✅ **Cost**: No load balancer charges
- ✅ **Speed**: Instant access (no IP provisioning wait)
- ✅ **Simplicity**: Perfect for testing and development

---

## 🚀 Quick Start

### 1. Start Port Forwarding

**Option A: Use the helper script (Recommended)**
```bash
./scripts/port-forward.sh
```

**Option B: Manual kubectl command**
```bash
kubectl port-forward -n rust-test svc/rust-datadog-otel 8080:80
```

### 2. Test the API

In a **new terminal**:
```bash
./scripts/test-api.sh http://localhost:8080
```

---

## 📋 Detailed Setup

### Three Terminal Workflow

For comprehensive testing, use three terminals:

**Terminal 1: Port Forward**
```bash
./scripts/port-forward.sh
```
Output:
```
==========================================
  Port Forward to Rust Datadog OTEL
==========================================

  Namespace: rust-test
  Service: rust-datadog-otel
  Local Port: 8080
  Service Port: 80

Starting port forward...
  Local:  http://localhost:8080
  Remote: rust-datadog-otel:80 (namespace: rust-test)

Press Ctrl+C to stop port forwarding

==========================================

Forwarding from 127.0.0.1:8080 -> 8080
Forwarding from [::1]:8080 -> 8080
```

**Terminal 2: API Testing**
```bash
# Test all endpoints
./scripts/test-api.sh http://localhost:8080

# Or manual testing
curl http://localhost:8080/health
curl http://localhost:8080/
```

**Terminal 3: Live Logs**
```bash
kubectl logs -n rust-test -l app=rust-datadog-otel -f
```

---

## 🔧 Configuration

### Environment Variables

The port-forward script supports these variables from `.env`:

```bash
# .env file
NAMESPACE="rust-test"           # Kubernetes namespace
SERVICE_NAME="rust-datadog-otel" # Service name
LOCAL_PORT="8080"                # Local port (your machine)
SERVICE_PORT="80"                # Service port (in cluster)
```

### Override Variables

```bash
# Use different local port
LOCAL_PORT=9090 ./scripts/port-forward.sh

# Use different namespace
NAMESPACE="production" ./scripts/port-forward.sh

# Combine overrides
NAMESPACE="staging" LOCAL_PORT=9090 ./scripts/port-forward.sh
```

---

## 🧪 Testing Scenarios

### Basic Health Check

```bash
# Terminal 1: Port forward
./scripts/port-forward.sh

# Terminal 2: Health check
curl http://localhost:8080/health
```

Expected response:
```json
{
  "status": "healthy",
  "version": "0.1.0",
  "timestamp": "2025-12-28T..."
}
```

### Full API Test Suite

```bash
# Run comprehensive tests
./scripts/test-api.sh http://localhost:8080
```

Tests include:
- Health endpoint
- User creation/retrieval
- Order processing
- Slow operations
- Database queries
- Error simulations

### Manual API Testing

```bash
# Create a user
curl -X POST http://localhost:8080/api/users \
  -H "Content-Type: application/json" \
  -d '{"name":"John Doe","email":"john@example.com"}'

# Get user
curl http://localhost:8080/api/users/user-id-here

# Create order
curl -X POST http://localhost:8080/api/orders \
  -H "Content-Type: application/json" \
  -d '{
    "user_id":"user-123",
    "items":[
      {"product_id":"prod-001","quantity":2,"price":29.99}
    ]
  }'
```

### Load Testing

```bash
# Install hey (HTTP load generator)
# macOS: brew install hey
# Linux: wget github.com/rakyll/hey/releases/.../hey

# Run load test
hey -n 1000 -c 10 http://localhost:8080/health
```

---

## 🔍 Monitoring & Debugging

### Check Port Forward Status

```bash
# In the port-forward terminal, you'll see:
Forwarding from 127.0.0.1:8080 -> 8080
Handling connection for 8080
Handling connection for 8080
```

Each line shows a new connection being handled.

### Check Datadog

1. **Traces**: Go to [APM > Traces](https://app.datadoghq.com/apm/traces)
   - Filter: `service:rust-datadog-otel`
   - You should see traces from your tests

2. **Logs**: Go to [Logs](https://app.datadoghq.com/logs)
   - Search: `service:rust-datadog-otel`
   - See structured logs with trace correlation

3. **Service Map**: [APM > Service Map](https://app.datadoghq.com/apm/map)
   - Find `rust-datadog-otel`
   - View service topology

### View Real-time Logs

```bash
# All pods
kubectl logs -n rust-test -l app=rust-datadog-otel -f

# Specific pod
kubectl logs -n rust-test <pod-name> -f

# With timestamps
kubectl logs -n rust-test -l app=rust-datadog-otel -f --timestamps

# Last 100 lines
kubectl logs -n rust-test -l app=rust-datadog-otel --tail=100
```

---

## ⚠️ Troubleshooting

### Port Forward Won't Start

**Problem**: "error: unable to forward port because pod is not running"

```bash
# Check pod status
kubectl get pods -n rust-test -l app=rust-datadog-otel

# If not running, check why
kubectl describe pod -n rust-test -l app=rust-datadog-otel

# Check recent events
kubectl get events -n rust-test --sort-by='.lastTimestamp'
```

### Connection Refused

**Problem**: "curl: (7) Failed to connect to localhost port 8080"

```bash
# 1. Verify port forward is running
# Look for "Forwarding from..." messages

# 2. Check if another process uses port 8080
lsof -i :8080
# Or on Linux: netstat -tlnp | grep 8080

# 3. Use different port
LOCAL_PORT=9090 ./scripts/port-forward.sh
curl http://localhost:9090/health
```

### Service Not Found

**Problem**: "Error from server (NotFound): services "rust-datadog-otel" not found"

```bash
# Check if service exists
kubectl get services -n rust-test

# Check if namespace exists
kubectl get namespaces

# Deploy if needed
./scripts/deploy.sh
```

### No Pods Running

**Problem**: "No running pods found"

```bash
# Check deployment
kubectl get deployment -n rust-test

# Check pod status
kubectl get pods -n rust-test -l app=rust-datadog-otel

# View pod logs
kubectl logs -n rust-test -l app=rust-datadog-otel

# Restart deployment
kubectl rollout restart deployment/rust-datadog-otel -n rust-test
```

### Port Already in Use

**Problem**: "bind: address already in use"

```bash
# Find what's using port 8080
lsof -i :8080

# Kill the process (if safe)
kill -9 <PID>

# Or use different port
LOCAL_PORT=9090 ./scripts/port-forward.sh
```

---

## 🎨 Advanced Usage

### Background Port Forward

```bash
# Start in background (not recommended for debugging)
kubectl port-forward -n rust-test svc/rust-datadog-otel 8080:80 &

# Get the process ID
PF_PID=$!

# Later, kill it
kill $PF_PID
```

### Multiple Services

```bash
# Terminal 1: Forward service 1
kubectl port-forward -n rust-test svc/rust-datadog-otel 8080:80

# Terminal 2: Forward service 2 (different app)
kubectl port-forward -n rust-test svc/another-service 8081:80
```

### Forward to Specific Pod

```bash
# List pods
kubectl get pods -n rust-test -l app=rust-datadog-otel

# Forward to specific pod
kubectl port-forward -n rust-test pod/<pod-name> 8080:8080
```

### Forward with Address Binding

```bash
# Allow connections from any IP (be careful!)
kubectl port-forward --address 0.0.0.0 -n rust-test svc/rust-datadog-otel 8080:80

# Allow from specific subnet
kubectl port-forward --address 192.168.1.100 -n rust-test svc/rust-datadog-otel 8080:80
```

---

## 📊 Comparison: Port Forward vs LoadBalancer

| Feature | Port Forward | LoadBalancer |
|---------|--------------|--------------|
| **Setup Time** | Instant | 2-5 minutes |
| **Cost** | Free | ~$15-20/month |
| **Security** | Private (localhost) | Public IP |
| **Use Case** | Testing, Development | Production |
| **Persistence** | Manual restart needed | Always available |
| **Multi-user** | No (local only) | Yes (public) |
| **Command** | `./scripts/port-forward.sh` | Auto via LoadBalancer |

---

## 🔒 Security Considerations

### Port Forward Security

✅ **Safe for development/testing:**
- Only accessible from your local machine
- No public exposure
- Easy to start/stop

⚠️ **Not for production:**
- Requires manual start
- Single user access
- Not persistent

### Best Practices

1. **Use port-forward for**:
   - Local testing
   - Development
   - Debugging
   - CI/CD test stages

2. **Use LoadBalancer/Ingress for**:
   - Production environments
   - Multi-user access
   - Always-on services
   - Public APIs

---

## 🚀 Quick Reference

```bash
# Start port forward
./scripts/port-forward.sh

# Test health
curl http://localhost:8080/health

# Run full tests
./scripts/test-api.sh http://localhost:8080

# Watch logs
kubectl logs -n rust-test -l app=rust-datadog-otel -f

# Stop port forward
# Press Ctrl+C in port-forward terminal
```

---

## 📚 Related Documentation

- [README.md](README.md) - Main project documentation
- [DEPLOYMENT.md](DEPLOYMENT.md) - Deployment guide
- [ENV_SETUP.md](ENV_SETUP.md) - Environment setup
- [kubectl port-forward docs](https://kubernetes.io/docs/tasks/access-application-cluster/port-forward-access-application-cluster/)

---

**Status**: ✅ Using ClusterIP with port-forward  
**Security**: Private, local-only access  
**Perfect for**: Testing and development  
**Last Updated**: December 28, 2025


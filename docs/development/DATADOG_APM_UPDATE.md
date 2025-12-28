# Datadog APM Update - Official SDK Integration

## ✅ Updated to Official Datadog Rust SDK

The project has been updated to use Datadog's official [`datadog-opentelemetry`](https://docs.datadoghq.com/tracing/trace_collection/custom_instrumentation/rust) crate instead of generic OpenTelemetry libraries.

---

## 🔄 What Changed

### Dependencies (Cargo.toml)

**Before** (Generic OpenTelemetry):
```toml
opentelemetry = { version = "0.31", features = ["trace", "logs"] }
opentelemetry_sdk = { version = "0.31", features = ["trace", "logs", "rt-tokio"] }
opentelemetry-otlp = { version = "0.27", features = ["trace", "logs", "grpc-tonic"] }
opentelemetry-semantic-conventions = "0.31"
```

**After** (Datadog Official SDK):
```toml
# Datadog APM - Official Datadog OpenTelemetry SDK
datadog-opentelemetry = "0.1"

# OpenTelemetry - Core API (required by datadog-opentelemetry)
opentelemetry = { version = "0.31", features = ["trace"] }
```

### Telemetry Initialization

**Before** (Manual OTLP Configuration):
```rust
let tracer = opentelemetry_otlp::new_pipeline()
    .tracing()
    .with_exporter(
        opentelemetry_otlp::new_exporter()
            .tonic()
            .with_endpoint(&otlp_endpoint)
            .with_timeout(std::time::Duration::from_secs(3)),
    )
    .with_trace_config(trace::Config::default()...)
    .install_batch(opentelemetry_sdk::runtime::Tokio)?;
```

**After** (Datadog Automatic Configuration):
```rust
// Automatically picks up DD_* environment variables
let tracer_provider = datadog_opentelemetry::tracing().init();
```

### Environment Variables

**Before** (OTLP-focused):
```bash
OTEL_SERVICE_NAME="rust-datadog-otel"
OTEL_EXPORTER_OTLP_ENDPOINT="http://localhost:4317"
OTEL_EXPORTER_OTLP_PROTOCOL="grpc"
```

**After** (Datadog-native):
```bash
DD_SERVICE="rust-datadog-otel"
DD_VERSION="0.1.0"
DD_ENV="development"
DD_AGENT_HOST="localhost"
DD_TRACE_ENABLED="true"
```

---

## 🎯 Benefits

### 1. Datadog-Specific Features

The official SDK includes Datadog-specific enhancements:
- ✅ Automatic configuration from DD_* environment variables
- ✅ Native Datadog Agent protocol support
- ✅ Optimized for Datadog backend
- ✅ Better trace correlation
- ✅ Simplified setup

### 2. Simpler Configuration

**Before**: Manual OTLP endpoint configuration
```rust
// Had to manually configure:
// - Endpoint URL
// - Protocol (gRPC/HTTP)
// - Resource attributes
// - Batch processor
// - Timeout settings
```

**After**: Automatic configuration
```rust
// Just one line!
let tracer_provider = datadog_opentelemetry::tracing().init();
// Reads DD_SERVICE, DD_VERSION, DD_ENV, DD_AGENT_HOST automatically
```

### 3. Better Datadog Integration

- ✅ Uses Datadog Agent API directly (port 8126) instead of OTLP (port 4317)
- ✅ Better performance with native protocol
- ✅ Automatic service discovery
- ✅ Enhanced trace metadata

---

## 📋 Configuration Reference

### Datadog Environment Variables

All configuration is done via environment variables:

| Variable | Description | Default | Example |
|----------|-------------|---------|---------|
| `DD_SERVICE` | Service name | - | `rust-datadog-otel` |
| `DD_VERSION` | Service version | - | `0.1.0` |
| `DD_ENV` | Environment | - | `development`, `production` |
| `DD_AGENT_HOST` | Datadog Agent hostname | `localhost` | `datadog-agent.datadog` |
| `DD_AGENT_PORT` | Datadog Agent APM port | `8126` | `8126` |
| `DD_TRACE_ENABLED` | Enable tracing | `true` | `true` / `false` |
| `DD_TRACE_SAMPLE_RATE` | Sampling rate | `1.0` | `0.0` - `1.0` |
| `DD_LOGS_INJECTION` | Inject trace IDs in logs | `false` | `true` / `false` |

### Kubernetes Deployment

Updated deployment configuration:

```yaml
env:
  # Datadog APM Configuration
  - name: DD_SERVICE
    value: "rust-datadog-otel"
  - name: DD_VERSION
    value: "0.1.0"
  - name: DD_ENV
    value: "development"
  
  # Point to Datadog Agent on same node
  - name: DD_AGENT_HOST
    valueFrom:
      fieldRef:
        fieldPath: status.hostIP
  
  - name: DD_TRACE_ENABLED
    value: "true"
  - name: DD_LOGS_INJECTION
    value: "true"
```

### Local Development

Updated local run script (loads from .env automatically):

```bash
# Automatically loads from .env if present
./scripts/local-run.sh

# Or set manually:
export DD_SERVICE="rust-datadog-otel"
export DD_VERSION="0.1.0"
export DD_ENV="local"
export DD_AGENT_HOST="localhost"
export DD_AGENT_PORT="8126"
export DD_TRACE_ENABLED="true"
export DD_LOGS_INJECTION="true"
export DD_TRACE_SAMPLE_RATE="1.0"
export RUST_LOG="info,rust_datadog_otel=debug"
```

---

## 🔌 Datadog Agent Requirements

### Agent Configuration

Ensure your Datadog Agent is configured to receive traces:

```yaml
# datadog-values.yaml
datadog:
  apm:
    enabled: true
    port: 8126  # Default APM port
```

No OTLP configuration needed anymore! The SDK communicates directly with the Datadog Agent's APM endpoint.

### Port Changes

| Protocol | Before | After | Notes |
|----------|--------|-------|-------|
| **OTLP gRPC** | Port 4317 | ~~Not used~~ | Removed OTLP dependency |
| **OTLP HTTP** | Port 4318 | ~~Not used~~ | Removed OTLP dependency |
| **Datadog APM** | - | **Port 8126** | Native Datadog protocol ✅ |

---

## 🚀 Migration Steps

If you're migrating from the old setup:

### 1. Update Dependencies

```bash
# Clean old dependencies
cargo clean

# Update Cargo.toml (already done)
# Build with new dependencies
cargo build
```

### 2. Update Environment Variables

**Remove OTLP variables:**
```bash
# No longer needed:
unset OTEL_EXPORTER_OTLP_ENDPOINT
unset OTEL_EXPORTER_OTLP_PROTOCOL
```

**Add Datadog variables:**
```bash
export DD_SERVICE="rust-datadog-otel"
export DD_VERSION="0.1.0"
export DD_ENV="development"
export DD_AGENT_HOST="localhost"
```

### 3. Redeploy

```bash
# Build and push new image
./scripts/build-and-push.sh

# Deploy with updated configuration
./scripts/deploy.sh
```

### 4. Verify

```bash
# Check traces in Datadog
# APM > Services > rust-datadog-otel

# Check agent connectivity
kubectl logs -n rust-test -l app=rust-datadog-otel | grep "Datadog APM"
```

---

## 📊 Code Examples

### Creating Spans (No Change)

The application code remains the same - still using `#[instrument]` macro:

```rust
#[instrument]
async fn create_user(
    State(state): State<Arc<AppState>>,
    Json(payload): Json<CreateUserRequest>,
) -> impl IntoResponse {
    info!(
        user_name = %payload.name,
        user_email = %payload.email,
        "Creating new user"
    );
    // ... rest of code
}
```

### Manual Span Creation

If you need manual span creation, use OpenTelemetry API:

```rust
use opentelemetry::{global, trace::Tracer};

let tracer = global::tracer("my-component");

tracer.in_span("operation_name", |cx| {
    // Your code here
    println!("Doing work...");
});
```

### Adding Span Attributes

```rust
use opentelemetry::trace::{Tracer, TraceContextExt};
use opentelemetry::KeyValue;

tracer.in_span("operation", |cx| {
    let span = cx.span();
    span.set_attribute(KeyValue::new("customer.id", "12345"));
    span.set_attribute(KeyValue::new("http.method", "GET"));
});
```

---

## 🔍 Datadog Agent Verification

### Check Agent is Receiving Traces

```bash
# In Kubernetes
kubectl exec -n datadog <datadog-agent-pod> -- agent status

# Look for APM section:
# ========
# APM Agent
# ========
#   Status: Running
#   Pid: 123
#   Uptime: 1 day
#   Mem alloc: 12.34 MB
#   
#   Receiver (APM)
#   ==============
#     Traces received: 1234
#     Traces filtered: 0
#     Traces priority sampled: 1234
```

### Test Trace Flow

```bash
# 1. Port forward to your app
./scripts/port-forward.sh

# 2. Generate traces
curl http://localhost:8080/health
curl http://localhost:8080/api/users/test-123

# 3. Check in Datadog UI
# APM > Traces > Filter: service:rust-datadog-otel
```

---

## 📚 References

### Official Documentation
- **Datadog Rust Custom Instrumentation**: https://docs.datadoghq.com/tracing/trace_collection/custom_instrumentation/rust
- **Datadog Rust Compatibility**: https://docs.datadoghq.com/tracing/trace_collection/compatibility/rust/
- **OpenTelemetry API**: https://docs.rs/opentelemetry/
- **datadog-opentelemetry Crate**: https://docs.rs/datadog-opentelemetry/

### Blog Posts
- **Monitor Rust with OpenTelemetry**: https://www.datadoghq.com/blog/monitor-rust-applications-opentelemetry/

---

## ⚠️ Breaking Changes

### What's Removed

1. ❌ **OTLP Dependencies**: No longer using `opentelemetry-otlp`, `opentelemetry_sdk`
2. ❌ **OTLP Environment Variables**: No longer reading `OTEL_EXPORTER_OTLP_*`
3. ❌ **OTLP Ports**: No longer connecting to ports 4317/4318

### What's Changed

1. ✅ **Initialization**: Now uses `datadog_opentelemetry::tracing().init()`
2. ✅ **Configuration**: Uses DD_* environment variables
3. ✅ **Agent Communication**: Uses Datadog Agent port 8126

### What Stays the Same

1. ✅ **Application Code**: `#[instrument]` macros still work
2. ✅ **OpenTelemetry API**: Can still use standard OTel API
3. ✅ **Tracing Integration**: `tracing` crate integration unchanged
4. ✅ **Log Correlation**: Still works with JSON logs

---

## ✨ Summary

| Aspect | Before | After |
|--------|--------|-------|
| **SDK** | Generic OpenTelemetry | ✅ Datadog Official SDK |
| **Protocol** | OTLP (gRPC) | ✅ Datadog Agent API |
| **Configuration** | Manual setup | ✅ Automatic from env vars |
| **Dependencies** | 4 OTel crates | ✅ 2 crates (simpler) |
| **Agent Port** | 4317 (OTLP) | ✅ 8126 (Datadog APM) |
| **Setup Complexity** | Complex | ✅ Simple (1 line init) |
| **Datadog Features** | Limited | ✅ Full native support |

---

**Status**: ✅ **Updated to Datadog Official SDK**  
**Reference**: [Datadog Rust Documentation](https://docs.datadoghq.com/tracing/trace_collection/custom_instrumentation/rust)  
**Compatibility**: OpenTelemetry 0.31, Rust 1.84+  
**Last Updated**: December 28, 2025


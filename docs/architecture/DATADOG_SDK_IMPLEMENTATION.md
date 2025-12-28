# Datadog OpenTelemetry SDK Implementation

## ✅ Successfully Implemented with `datadog-opentelemetry` 0.2.1

This document describes the successful implementation of Datadog's official OpenTelemetry SDK for Rust.

## 📦 Dependencies

### Cargo.toml

```toml
[package]
name = "rust-datadog-otel"
version = "0.1.0"
edition = "2021"
rust-version = "1.85"  # Required by datadog-opentelemetry dependencies

[dependencies]
# Datadog APM - Official Datadog OpenTelemetry SDK
datadog-opentelemetry = "0.2.1"

# OpenTelemetry - Core API and SDK (required by datadog-opentelemetry)
opentelemetry = { version = "0.31", features = ["trace", "logs"] }
opentelemetry_sdk = "0.31"  # For SdkTracerProvider with shutdown()

# Tracing integration - Bridge between tracing and OpenTelemetry
tracing = "0.1"
tracing-subscriber = { version = "0.3", features = ["env-filter", "json"] }
tracing-opentelemetry = "0.32"
```

## 🔧 Implementation

### src/telemetry.rs

```rust
use datadog_opentelemetry;
use opentelemetry::global;
use opentelemetry_sdk::trace::SdkTracerProvider;
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt, EnvFilter};

pub fn init_telemetry() -> Result<SdkTracerProvider, Box<dyn std::error::Error>> {
    // Get configuration from DD_* environment variables
    let service_name = std::env::var("DD_SERVICE")
        .unwrap_or_else(|_| "rust-datadog-otel".to_string());
    
    let service_version = std::env::var("DD_VERSION")
        .unwrap_or_else(|_| env!("CARGO_PKG_VERSION").to_string());
    
    let deployment_environment = std::env::var("DD_ENV")
        .unwrap_or_else(|_| "development".to_string());

    let dd_agent_host = std::env::var("DD_AGENT_HOST")
        .or_else(|_| std::env::var("HOST_IP"))
        .unwrap_or_else(|_| "localhost".to_string());

    println!("Initializing Datadog APM");
    println!("  Service: {}", service_name);
    println!("  Version: {}", service_version);
    println!("  Environment: {}", deployment_environment);
    println!("  Agent Host: {}", dd_agent_host);
    println!("  Using: datadog-opentelemetry SDK v0.2.1");

    // Initialize the Datadog tracer provider using the official SDK
    // This picks up DD_* env var configuration and initializes the global tracer provider
    let tracer_provider = datadog_opentelemetry::tracing()
        .init();

    // Get tracer from the global provider (official Datadog pattern)
    let tracer = global::tracer("rust-datadog-otel");

    // Create tracing layer with OpenTelemetry
    let telemetry_layer = tracing_opentelemetry::layer().with_tracer(tracer);

    // Create logging layer with JSON formatting for Datadog log correlation
    let log_level = std::env::var("RUST_LOG")
        .unwrap_or_else(|_| "info,rust_datadog_otel=debug".to_string());
    
    let env_filter = EnvFilter::try_from_default_env()
        .or_else(|_| EnvFilter::try_new(&log_level))
        .unwrap();

    // Initialize tracing subscriber with both layers
    tracing_subscriber::registry()
        .with(env_filter)
        .with(telemetry_layer)
        .with(
            tracing_subscriber::fmt::layer()
                .json()
                .with_current_span(true)
                .with_span_list(true)
                .with_target(true)
                .with_thread_ids(true)
                .with_thread_names(true)
        )
        .init();

    println!("Datadog APM initialized successfully");

    Ok(tracer_provider)
}

/// Shutdown OpenTelemetry gracefully
pub fn shutdown_telemetry(tracer_provider: SdkTracerProvider) {
    println!("Shutting down telemetry...");
    match tracer_provider.shutdown() {
        Ok(_) => println!("Telemetry shutdown complete"),
        Err(e) => eprintln!("Error shutting down telemetry: {:?}", e),
    }
}
```

### In main.rs:

```rust
#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    // Initialize and store the tracer provider
    let tracer_provider = telemetry::init_telemetry()?;

    // ... your application code ...

    // Run server with graceful shutdown
    let result = axum::serve(listener, app)
        .with_graceful_shutdown(shutdown_signal())
        .await;

    // Shutdown telemetry to flush remaining spans
    telemetry::shutdown_telemetry(tracer_provider);

    result?;
    Ok(())
}

async fn shutdown_signal() {
    tokio::signal::ctrl_c()
        .await
        .expect("failed to install CTRL+C signal handler");
    info!("Shutdown signal received, shutting down gracefully...");
}
```

## 🌍 Environment Variables

The SDK automatically reads these environment variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `DD_SERVICE` | Service name for unified tagging | `rust-datadog-otel` |
| `DD_VERSION` | Service version | From `Cargo.toml` |
| `DD_ENV` | Environment (dev/staging/prod) | `development` |
| `DD_AGENT_HOST` | Datadog Agent hostname | `localhost` |
| `DD_TRACE_ENABLED` | Enable/disable tracing | `true` |
| `DD_LOGS_INJECTION` | Enable log correlation | `true` |
| `RUST_LOG` | Rust log level | `info,rust_datadog_otel=debug` |

## 🚀 Key Features

### 1. Official Datadog Pattern

Following the official Datadog documentation:

```rust
// Initialize and store the provider for shutdown
let tracer_provider = datadog_opentelemetry::tracing().init();

// Use global::tracer() to get the tracer (not tracer_provider.tracer())
let tracer = global::tracer("rust-datadog-otel");

// Shutdown on exit to flush pending traces
tracer_provider.shutdown().expect("tracer shutdown error");
```

This pattern:
- ✅ Initializes the global tracer provider
- ✅ Uses `global::tracer()` for consistent access
- ✅ Properly shuts down to flush remaining spans
- ✅ Configures everything from DD_* environment variables

### 2. Automatic Configuration

The SDK reads standard Datadog environment variables (`DD_*`) automatically, providing:
- Service name and version
- Environment tagging
- Agent connection details
- Trace sampling configuration

### 3. Native Datadog Integration

Unlike generic OTLP exporters, the Datadog SDK:
- ✅ Uses Datadog-specific trace formats
- ✅ Properly handles Datadog trace IDs
- ✅ Implements Datadog sampling strategies
- ✅ Supports Datadog-specific features (runtime metrics, etc.)

## 📊 Comparison: Datadog SDK vs Standard OTLP

| Feature | `datadog-opentelemetry` SDK | Standard OTLP Exporter |
|---------|----------------------------|------------------------|
| **Setup Complexity** | ⭐ Simple (1 line) | ⭐⭐⭐ Complex (many lines) |
| **Configuration** | ✅ Automatic via DD_* vars | ❌ Manual resource setup |
| **Datadog Features** | ✅ Native support | ⚠️ Limited support |
| **Trace ID Format** | ✅ Datadog native | ⚠️ Converted |
| **Runtime Metrics** | ✅ Supported | ❌ Not available |
| **Maintenance** | ✅ Datadog maintained | ⚠️ Community maintained |

## 🏗️ Kubernetes Deployment

The deployment uses standard Datadog environment variables:

```yaml
env:
# Datadog Unified Service Tagging
- name: DD_SERVICE
  value: "rust-datadog-otel"
- name: DD_VERSION
  value: "0.1.0"
- name: DD_ENV
  value: "development"

# Datadog Agent connection
- name: DD_AGENT_HOST
  valueFrom:
    fieldRef:
      fieldPath: status.hostIP

# Additional configuration
- name: DD_TRACE_ENABLED
  value: "true"
- name: DD_LOGS_INJECTION
  value: "true"
- name: RUST_LOG
  value: "info,rust_datadog_otel=debug"
```

## ✅ Build & Run

### Local Development

```bash
# Set environment variables
export DD_SERVICE=rust-datadog-otel
export DD_VERSION=0.1.0
export DD_ENV=local
export DD_AGENT_HOST=localhost
export DD_TRACE_ENABLED=true
export RUST_LOG=info,rust_datadog_otel=debug

# Build and run
cargo build
cargo run
```

### Docker Build

```bash
docker build -t rust-datadog-otel:latest .
docker run -e DD_AGENT_HOST=host.docker.internal rust-datadog-otel:latest
```

### Kubernetes Deployment

```bash
# Build and push
./scripts/build-and-push.sh

# Deploy
./scripts/deploy.sh

# Test with port-forward
./scripts/port-forward.sh
```

## 🔍 Verification

### Application Logs

When the application starts, you should see:

```
Initializing Datadog APM
  Service: rust-datadog-otel
  Version: 0.1.0
  Environment: development
  Agent Host: localhost
  Using: datadog-opentelemetry SDK v0.2.1
Datadog APM initialized successfully
```

### Datadog Platform

1. **APM Traces**: Navigate to APM > Traces in Datadog
2. **Service Map**: Check APM > Service Map for `rust-datadog-otel`
3. **Logs**: View logs with trace correlation in Logs Explorer

## 🐛 Troubleshooting

### Connection Refused Warning

If you see:
```
WARN: Error while fetching /info: Connection refused
```

This is normal when the Datadog Agent is not running locally. In Kubernetes, the SDK will connect to the agent via `DD_AGENT_HOST`.

### No Traces Appearing

1. **Check Agent is running**:
   ```bash
   kubectl get pods -n datadog
   ```

2. **Check environment variables**:
   ```bash
   kubectl exec -n rust-test deployment/rust-datadog-otel -- env | grep DD_
   ```

3. **Check application logs**:
   ```bash
   kubectl logs -n rust-test deployment/rust-datadog-otel
   ```

4. **Verify Agent OTLP is enabled** in `datadog/datadog-values.yaml`:
   ```yaml
   datadog:
     apm:
       enabled: true
   ```

## 📚 References

- [Datadog Rust Compatibility](https://docs.datadoghq.com/tracing/trace_collection/compatibility/rust/)
- [Datadog Custom Instrumentation for Rust](https://docs.datadoghq.com/tracing/trace_collection/custom_instrumentation/rust)
- [OpenTelemetry Rust Documentation](https://docs.rs/opentelemetry/latest/opentelemetry/)
- [datadog-opentelemetry crate](https://crates.io/crates/datadog-opentelemetry)

## 🎯 Next Steps

1. ✅ Application compiles successfully
2. ✅ Application runs with Datadog SDK
3. ⏭️ Build Docker image
4. ⏭️ Deploy to Kubernetes
5. ⏭️ Verify traces in Datadog
6. ⏭️ Test all API endpoints
7. ⏭️ Monitor performance metrics

## 📝 Version History

| Date | Version | Changes |
|------|---------|---------|
| 2025-12-28 | 0.2.1 | ✅ Successfully implemented with `datadog-opentelemetry` 0.2.1 |
| 2025-12-28 | 0.1.0 | ❌ Failed with version conflicts |

## 🙌 Success!

The application now uses Datadog's official OpenTelemetry SDK, providing:
- ✅ Simplified configuration
- ✅ Native Datadog integration
- ✅ Better performance
- ✅ Official support and updates
- ✅ Full compatibility with Datadog features


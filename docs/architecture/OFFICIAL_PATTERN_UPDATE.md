# Official Datadog Pattern Implementation

## ✅ Updated to Match Official Datadog Documentation

Based on the official Datadog Rust documentation, the implementation has been updated to follow the recommended pattern.

## 📝 Key Changes

### 1. Use `global::tracer()` Instead of `tracer_provider.tracer()`

**Before:**
```rust
let tracer_provider = datadog_opentelemetry::tracing().init();
let tracer = tracer_provider.tracer("rust-datadog-otel");  // ❌ Not the official pattern
```

**After (Official Pattern):**
```rust
let tracer_provider = datadog_opentelemetry::tracing().init();
let tracer = global::tracer("rust-datadog-otel");  // ✅ Official pattern
```

**Why?** The official pattern uses `global::tracer()` to get the tracer from the global provider that was registered by `init()`.

### 2. Return TracerProvider for Proper Shutdown

**Before:**
```rust
pub fn init_telemetry() -> Result<(), Box<dyn std::error::Error>> {
    let tracer_provider = datadog_opentelemetry::tracing().init();
    // ... 
    Ok(())  // ❌ Provider is lost
}
```

**After (Official Pattern):**
```rust
pub fn init_telemetry() -> Result<SdkTracerProvider, Box<dyn std::error::Error>> {
    let tracer_provider = datadog_opentelemetry::tracing().init();
    // ...
    Ok(tracer_provider)  // ✅ Return for shutdown
}
```

**Why?** The provider must be kept alive and explicitly shut down before application exit to flush pending traces.

### 3. Implement Proper Shutdown

**Added:**
```rust
pub fn shutdown_telemetry(tracer_provider: SdkTracerProvider) {
    println!("Shutting down telemetry...");
    match tracer_provider.shutdown() {
        Ok(_) => println!("Telemetry shutdown complete"),
        Err(e) => eprintln!("Error shutting down telemetry: {:?}", e),
    }
}
```

**Why?** Ensures all pending traces are flushed to Datadog Agent before the application exits.

### 4. Main Function with Graceful Shutdown

**Updated main.rs:**
```rust
#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    // Store the tracer provider
    let tracer_provider = telemetry::init_telemetry()?;

    // ... application setup ...

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

**Why?** Properly handles Ctrl+C and ensures telemetry is flushed even during graceful shutdown.

### 5. Added opentelemetry_sdk Dependency

**Updated Cargo.toml:**
```toml
[dependencies]
# Datadog APM - Official Datadog OpenTelemetry SDK
datadog-opentelemetry = "0.2.1"

# OpenTelemetry - Core API and SDK
opentelemetry = { version = "0.31", features = ["trace", "logs"] }
opentelemetry_sdk = "0.31"  # For SdkTracerProvider with shutdown()

# Tracing integration
tracing-opentelemetry = "0.32"
```

**Why?** Need `SdkTracerProvider` concrete type which has the `shutdown()` method.

## 📚 Official Documentation Reference

From: https://docs.datadoghq.com/tracing/trace_collection/custom_instrumentation/rust

```rust
use datadog_opentelemetry;
use opentelemetry::{global, trace::Tracer};
use std::time::Duration;

fn main() {
    // This picks up env var configuration (like DD_SERVICE)
    // and initializes the global tracer provider
    let tracer_provider = datadog_opentelemetry::tracing()
        .init();

    // --- Your application code starts here ---
    // You can now use the standard OpenTelemetry API
    
    let tracer = global::tracer("my-component");
    
    tracer.in_span("my-operation", |_cx| {
        // ... do work ...
    });

    println!("Doing work...");

    // --- Your application code ends here ---

    // Shut down the tracer provider to flush remaining spans
    tracer_provider.shutdown_with_timeout(Duration::from_secs(5))
        .expect("tracer shutdown error");
}
```

## ✅ Verification

### Build Status
```bash
✅ Compilation: SUCCESS
✅ Application runs successfully
✅ Using: datadog-opentelemetry SDK v0.2.1
✅ Following official Datadog pattern
```

### Console Output
```
Initializing Datadog APM
  Service: rust-datadog-otel
  Version: 0.1.0
  Environment: development
  Agent Host: localhost
  Using: datadog-opentelemetry SDK v0.2.1
Datadog APM initialized successfully
```

## 🎯 Benefits of Official Pattern

| Benefit | Description |
|---------|-------------|
| ✅ **Official Support** | Follows Datadog's documented approach |
| ✅ **Proper Shutdown** | Ensures traces are flushed on exit |
| ✅ **Global Tracer** | Consistent tracer access across the app |
| ✅ **Graceful Handling** | Handles Ctrl+C and shutdown signals |
| ✅ **Best Practices** | Aligns with OpenTelemetry patterns |

## 📋 Summary of Files Changed

1. **Cargo.toml** - Added `opentelemetry_sdk = "0.31"`
2. **src/telemetry.rs** - Updated to return provider and use `global::tracer()`
3. **src/main.rs** - Added graceful shutdown handling
4. **Documentation** - Updated to reflect official pattern

## 🚀 Next Steps

The application now correctly implements the official Datadog pattern and is ready for:

1. ✅ Local testing
2. ✅ Docker build
3. ✅ Kubernetes deployment
4. ✅ Production use

All traces will be properly flushed to Datadog Agent on application exit.


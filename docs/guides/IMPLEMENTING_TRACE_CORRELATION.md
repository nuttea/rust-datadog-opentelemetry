# Quick Start: Implementing Trace-Log Correlation

**Time Required**: 2-4 hours  
**Difficulty**: Intermediate  
**Prerequisites**: Understanding of Rust, tracing, and OpenTelemetry

## 🎯 Goal

Add `dd.trace_id` and `dd.span_id` to all logs so Datadog can correlate logs with traces.

## 🚀 Quick Implementation (Recommended)

### Step 1: Create Helper Module

Create `src/trace_context.rs`:

```rust
use opentelemetry::trace::TraceContextExt;
use tracing::Span;

/// Extract current trace context for Datadog correlation
pub fn current_trace_context() -> Option<(String, String)> {
    let current_span = Span::current();
    let context = current_span.context();
    let span_context = context.span().span_context();

    if !span_context.is_valid() {
        return None;
    }

    // Convert OpenTelemetry trace_id (128-bit) to Datadog format (lower 64-bit decimal)
    let trace_id_bytes = span_context.trace_id().to_bytes();
    let trace_id_lower = u64::from_be_bytes([
        trace_id_bytes[8], trace_id_bytes[9], trace_id_bytes[10], trace_id_bytes[11],
        trace_id_bytes[12], trace_id_bytes[13], trace_id_bytes[14], trace_id_bytes[15],
    ]);

    // Convert span_id to decimal
    let span_id_bytes = span_context.span_id().to_bytes();
    let span_id_decimal = u64::from_be_bytes(span_id_bytes);

    Some((trace_id_lower.to_string(), span_id_decimal.to_string()))
}

/// Macro to add Datadog trace context to logs
#[macro_export]
macro_rules! log_with_trace {
    // info_trace!("message")
    ($level:ident, $msg:expr) => {
        if let Some((trace_id, span_id)) = $crate::trace_context::current_trace_context() {
            tracing::$level!(
                dd.trace_id = %trace_id,
                dd.span_id = %span_id,
                dd.service = %std::env::var("DD_SERVICE").unwrap_or_else(|_| "rust-datadog-otel".to_string()),
                dd.env = %std::env::var("DD_ENV").unwrap_or_else(|_| "development".to_string()),
                dd.version = %std::env::var("DD_VERSION").unwrap_or_else(|_| "0.1.0".to_string()),
                $msg
            );
        } else {
            tracing::$level!($msg);
        }
    };
    
    // info_trace!(field1 = %value1, field2 = %value2, "message")
    ($level:ident, $($field:tt = $value:expr),+ , $msg:expr) => {
        if let Some((trace_id, span_id)) = $crate::trace_context::current_trace_context() {
            tracing::$level!(
                dd.trace_id = %trace_id,
                dd.span_id = %span_id,
                dd.service = %std::env::var("DD_SERVICE").unwrap_or_else(|_| "rust-datadog-otel".to_string()),
                dd.env = %std::env::var("DD_ENV").unwrap_or_else(|_| "development".to_string()),
                dd.version = %std::env::var("DD_VERSION").unwrap_or_else(|_| "0.1.0".to_string()),
                $($field = $value),+,
                $msg
            );
        } else {
            tracing::$level!($($field = $value),+, $msg);
        }
    };
}

// Convenience macros for each log level
#[macro_export]
macro_rules! info_trace {
    ($($arg:tt)+) => { $crate::log_with_trace!(info, $($arg)+) };
}

#[macro_export]
macro_rules! error_trace {
    ($($arg:tt)+) => { $crate::log_with_trace!(error, $($arg)+) };
}

#[macro_export]
macro_rules! warn_trace {
    ($($arg:tt)+) => { $crate::log_with_trace!(warn, $($arg)+) };
}

#[macro_export]
macro_rules! debug_trace {
    ($($arg:tt)+) => { $crate::log_with_trace!(debug, $($arg)+) };
}
```

### Step 2: Update main.rs

Add the module declaration at the top of `src/main.rs`:

```rust
mod telemetry;
mod trace_context;  // <- Add this line
```

### Step 3: Replace Logging Statements

Replace existing log statements with trace-aware versions:

**Before:**
```rust
info!("Creating new user");
error!(error_type = %error_type, "Simulating error");
```

**After:**
```rust
info_trace!("Creating new user");
error_trace!(error_type = %error_type, "Simulating error");
```

### Step 4: Example Handler Update

Here's a complete before/after example:

**Before:**
```rust
#[instrument(skip(state))]
async fn create_user(
    State(state): State<Arc<AppState>>,
    Json(payload): Json<CreateUserRequest>,
) -> Json<User> {
    info!(
        name = %payload.name,
        email = %payload.email,
        "Creating new user"
    );

    // Validation
    if payload.name.is_empty() {
        warn!("User creation failed: empty name");
        return Json(User { /* error */ });
    }

    // Create user
    let user = User {
        id: uuid::Uuid::new_v4().to_string(),
        name: payload.name,
        email: payload.email,
        created_at: chrono::Utc::now().to_rfc3339(),
    };

    info!(user_id = %user.id, "User created successfully");

    Json(user)
}
```

**After:**
```rust
#[instrument(skip(state))]
async fn create_user(
    State(state): State<Arc<AppState>>,
    Json(payload): Json<CreateUserRequest>,
) -> Json<User> {
    info_trace!(
        name = %payload.name,
        email = %payload.email,
        "Creating new user"
    );

    // Validation
    if payload.name.is_empty() {
        warn_trace!("User creation failed: empty name");
        return Json(User { /* error */ });
    }

    // Create user
    let user = User {
        id: uuid::Uuid::new_v4().to_string(),
        name: payload.name,
        email: payload.email,
        created_at: chrono::Utc::now().to_rfc3339(),
    };

    info_trace!(user_id = %user.id, "User created successfully");

    Json(user)
}
```

## 🧪 Testing

### Local Test

```bash
# Start the application
./scripts/local-run.sh

# In another terminal, make a request
curl -X POST http://localhost:8080/api/users \
  -H "Content-Type: application/json" \
  -d '{"name":"Test","email":"test@example.com"}'

# Check logs for dd.trace_id
# You should see something like:
# {"level":"INFO","dd.trace_id":"1234567890","dd.span_id":"9876543210",...}
```

### Expected Log Format

```json
{
  "timestamp": "2025-12-28T10:30:45.123Z",
  "level": "INFO",
  "message": "Creating new user",
  "dd.trace_id": "7621889953578991300",
  "dd.span_id": "10876861900508630237",
  "dd.service": "rust-datadog-otel",
  "dd.env": "development",
  "dd.version": "0.1.0",
  "name": "Test User",
  "email": "test@example.com",
  "target": "rust_datadog_otel"
}
```

### Kubernetes Test

```bash
# Build and deploy
./scripts/build-and-push.sh
./scripts/deploy.sh

# Generate traffic
./scripts/load-test.sh http://localhost:8080

# Check logs
kubectl logs -f deployment/rust-datadog-otel -n rust-test

# Verify in Datadog
./scripts/verify-correlation.sh
```

### Datadog Verification

1. **Go to APM → Traces**
   - Find a recent trace
   - Look for "Logs" tab
   - Should show correlated logs

2. **Go to Logs → Search**
   - Filter: `service:rust-datadog-otel`
   - Click on a log
   - Look for "View Trace" button
   - Should navigate to the trace

## 📋 Complete Checklist

### Implementation
- [ ] Create `src/trace_context.rs`
- [ ] Add `mod trace_context;` to `src/main.rs`
- [ ] Replace `info!` with `info_trace!`
- [ ] Replace `error!` with `error_trace!`
- [ ] Replace `warn!` with `warn_trace!`
- [ ] Replace `debug!` with `debug_trace!`

### Testing
- [ ] Build locally: `cargo build`
- [ ] Test locally: Check log format
- [ ] Build Docker: `./scripts/build-and-push.sh`
- [ ] Deploy: `./scripts/deploy.sh`
- [ ] Generate traffic: `./scripts/load-test.sh`
- [ ] Check Datadog UI for correlation

### Verification
- [ ] Logs contain `dd.trace_id` (decimal)
- [ ] Logs contain `dd.span_id` (decimal)
- [ ] Logs contain `dd.service`, `dd.env`, `dd.version`
- [ ] Trace view shows "Logs" tab
- [ ] Log view shows "View Trace" button
- [ ] Navigation works both directions

## 🔍 Troubleshooting

### Issue: No dd.trace_id in logs

**Check:**
- Is the code running inside an instrumented span?
- Is OpenTelemetry initialized correctly?
- Are you using the `_trace` macros?

**Solution:**
- Ensure handlers have `#[instrument]` attribute
- Check telemetry initialization in logs
- Verify macros are being used correctly

### Issue: trace_id is "0" or invalid

**Check:**
- Is the span context valid?
- Is the tracer provider properly initialized?

**Solution:**
- Check `telemetry::init_telemetry()` is called before routes
- Verify `DD_AGENT_HOST` is set correctly

### Issue: IDs don't match in Datadog

**Check:**
- Format conversion (hex → decimal)
- Using lower 64 bits of trace_id

**Solution:**
- Review `current_trace_context()` implementation
- Verify byte order conversion

## 📊 Performance Impact

**Expected overhead per log statement:**
- Additional CPU: < 1 microsecond
- Memory: ~40 bytes per log
- Network: ~100 bytes per log (for trace IDs)

**Minimal impact** - suitable for production use.

## 🚀 Quick Start Commands

```bash
# 1. Create the trace_context.rs file
cat > src/trace_context.rs << 'EOF'
# ... (paste the code from Step 1)
EOF

# 2. Build and test locally
cargo build
./scripts/local-run.sh

# 3. Test with a request
curl -X POST http://localhost:8080/api/users \
  -H "Content-Type: application/json" \
  -d '{"name":"Test","email":"test@test.com"}'

# 4. Check logs
# Look for dd.trace_id in the output

# 5. Deploy to Kubernetes
./scripts/build-and-push.sh
./scripts/deploy.sh

# 6. Verify correlation
./scripts/verify-correlation.sh
```

## 📚 Additional Resources

- [Full Implementation Plan](../architecture/TRACE_LOG_CORRELATION_IMPLEMENTATION.md)
- [Correlation Analysis](../development/CORRELATION_ANALYSIS.md)
- [Datadog Documentation](https://docs.datadoghq.com/tracing/other_telemetry/connect_logs_and_traces/)

---

**Need Help?**

Review the detailed implementation plan in `docs/architecture/TRACE_LOG_CORRELATION_IMPLEMENTATION.md` for more options and explanations.


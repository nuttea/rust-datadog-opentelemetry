# Trace-Log Correlation in Datadog for Rust

This guide explains how trace-log correlation works with Datadog's Rust OpenTelemetry SDK and how to verify it's working correctly.

## 🎯 Overview

Trace-log correlation allows you to connect logs with their corresponding traces in Datadog, enabling you to:
- Navigate from a trace to related logs
- Navigate from a log to its trace
- See the full context of what happened during a request

## 🔍 Current Implementation

### What's Configured

**1. OpenTelemetry Tracing Layer** (`src/telemetry.rs`):
```rust
let telemetry_layer = tracing_opentelemetry::layer().with_tracer(tracer);
```
This propagates OpenTelemetry trace context through your application.

**2. JSON Logging with Span Context** (`src/telemetry.rs`):
```rust
tracing_subscriber::fmt::layer()
    .json()
    .with_current_span(true)     // ✅ Includes current span info
    .with_span_list(true)         // ✅ Includes span hierarchy
    .with_target(true)            // ✅ Includes log target
    .with_thread_ids(true)        // ✅ Includes thread info
```

**3. Datadog Environment Variables** (`k8s/deployment.yaml`):
```yaml
- name: DD_LOGS_INJECTION
  value: "true"
- name: DD_SERVICE
  value: "rust-datadog-otel"
- name: DD_ENV
  value: "development"
- name: DD_VERSION
  value: "0.1.0"
```

## ⚠️ Current Limitation

**The current setup has a potential issue**: The `tracing-opentelemetry` crate includes span information in logs, but it uses OpenTelemetry's **hexadecimal format** for trace and span IDs:
- Example: `trace_id: "0x1234567890abcdef"`

However, Datadog expects **decimal format** with specific field names:
- `dd.trace_id`: "1311768467294899695" (decimal)
- `dd.span_id`: "4887526791234567890" (decimal)

## ✅ How to Verify Correlation

### Step 1: Check Log Format

Run the application and examine a log entry:

```bash
# Local
./scripts/local-run.sh

# Or in Kubernetes
kubectl logs -f deployment/rust-datadog-otel -n rust-test
```

**Look for trace context in JSON logs:**

```json
{
  "timestamp": "2024-01-15T10:30:45.123Z",
  "level": "INFO",
  "message": "Creating new user",
  "target": "rust_datadog_otel",
  "span": {
    "name": "create_user",
    "trace_id": "0x1234567890abcdef",  // ⚠️ Hex format
    "span_id": "0x9876543210fedcba"    // ⚠️ Hex format
  },
  "spans": [
    {
      "name": "create_user"
    }
  ]
}
```

### Step 2: Check Datadog Logs

1. Go to **Datadog → Logs → Search**
2. Filter: `service:rust-datadog-otel`
3. Click on a log entry
4. Look for these fields in the log details:

**Expected fields for correlation:**
- `dd.trace_id` (decimal format)
- `dd.span_id` (decimal format)
- `dd.service`
- `dd.env`
- `dd.version`

### Step 3: Test Correlation

1. **Generate a request:**
   ```bash
   curl -X POST http://localhost:8080/api/users \
     -H "Content-Type: application/json" \
     -d '{"name":"Test User","email":"test@example.com"}'
   ```

2. **Find the trace in Datadog:**
   - Go to **APM → Traces**
   - Filter: `service:rust-datadog-otel`
   - Find the `/api/users` POST request

3. **Check for logs in the trace:**
   - Open the trace
   - Look for a "Logs" tab or section
   - If correlation works, you'll see associated logs

4. **Check from log to trace:**
   - Go to **Logs → Search**
   - Find a log from the request
   - Look for a "View Trace" link or trace ID
   - Clicking it should take you to the trace

## 🔧 Verification Script

Use the load test script to generate traffic:

```bash
# Start port-forward
./scripts/port-forward.sh

# Generate load with various endpoints
./scripts/load-test.sh http://localhost:8080 5 1 5
```

This will create multiple traces and logs for testing correlation.

## 📊 Expected Behavior

### ✅ If Correlation Works:

**In Datadog Traces:**
- Each span shows associated log messages
- "Logs" tab shows related logs
- Timeline includes log events

**In Datadog Logs:**
- Logs have `dd.trace_id` and `dd.span_id` attributes
- "View Trace" button/link appears
- Clicking navigates to the associated trace
- Trace context shows in log attributes

### ❌ If Correlation Doesn't Work:

**Symptoms:**
- No "Logs" section in trace view
- No "View Trace" link in log view
- `dd.trace_id` and `dd.span_id` missing from logs
- Only `span.trace_id` in hex format present

## 🛠️ Potential Solutions

### Option 1: Datadog Agent Log Processing

The Datadog Agent can parse OpenTelemetry trace IDs from logs and convert them to Datadog format.

**Check Datadog Agent configuration:**
```yaml
# In datadog-values.yaml or agent config
logs_config:
  use_opentelemetry_trace_id_pattern: true
```

This tells the agent to look for OpenTelemetry trace IDs and convert them.

### Option 2: Custom Log Formatter

Create a custom tracing layer that formats trace IDs in Datadog format:

```rust
// This would require implementing a custom layer
// that extracts trace_id/span_id from OpenTelemetry context
// and formats them as Datadog expects
```

### Option 3: Use Datadog's Logging Library

If direct log correlation is critical, consider using Datadog's logging SDK alongside OpenTelemetry tracing.

## 🔍 Debugging Checklist

- [ ] Logs are in JSON format
- [ ] `DD_LOGS_INJECTION=true` is set
- [ ] `DD_SERVICE`, `DD_ENV`, `DD_VERSION` are set
- [ ] Datadog Agent is receiving logs from the pod
- [ ] Datadog Agent is receiving traces
- [ ] Both logs and traces have the same service name
- [ ] Logs contain span context (even if in hex)
- [ ] Datadog Agent version supports OpenTelemetry correlation

## 📝 Check Datadog Agent Logs

```bash
# Check if agent is processing logs correctly
kubectl logs -f deployment/datadog -n datadog | grep -i "trace"

# Check agent status
kubectl exec -it deployment/datadog -n datadog -- agent status
```

Look for:
- "Logs Agent" status
- "APM Agent" status
- Any warnings about log/trace correlation

## 🎯 Quick Test

Run this complete test:

```bash
# 1. Start port-forward
./scripts/port-forward.sh

# 2. Make a request
curl -X POST http://localhost:8080/api/users \
  -H "Content-Type: application/json" \
  -d '{"name":"Correlation Test","email":"test@test.com"}'

# 3. Check application logs
kubectl logs -l app=rust-datadog-otel -n rust-test --tail=20

# 4. Go to Datadog
# - Check APM for the trace
# - Check Logs for the log entries
# - Verify if they're linked
```

## 📚 References

- [Datadog Rust Tracing](https://docs.datadoghq.com/tracing/trace_collection/custom_instrumentation/rust)
- [Datadog Log-Trace Correlation](https://docs.datadoghq.com/tracing/other_telemetry/connect_logs_and_traces/)
- [OpenTelemetry Trace Context](https://opentelemetry.io/docs/specs/otel/trace/api/#spancontext)
- [Tracing-OpenTelemetry Crate](https://docs.rs/tracing-opentelemetry/)

## 🚨 Known Issues

### Issue: Hex vs Decimal Format

OpenTelemetry uses 128-bit hex trace IDs (`0x...`), while Datadog uses 64-bit decimal IDs.

**Workaround**: The Datadog Agent should handle conversion if configured correctly.

### Issue: Missing dd.* Fields

If logs don't have `dd.trace_id` fields, the agent may not be configured to inject them.

**Solution**: Ensure `DD_LOGS_INJECTION=true` and agent has log collection enabled.

## 💡 Next Steps

1. **Run verification tests** as described above
2. **Check Datadog UI** for correlation indicators
3. **Review agent configuration** if correlation is missing
4. **Update this document** with your findings
5. **Consider custom formatter** if needed for your use case


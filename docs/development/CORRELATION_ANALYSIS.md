# Trace-Log Correlation Analysis Report

**Date**: December 28, 2025  
**Service**: rust-datadog-otel  
**Environment**: development  

## 🔍 Executive Summary

**Status: ❌ Trace-Log Correlation is NOT Working**

While both traces and logs are successfully being collected by Datadog, they are **NOT correlated**. The logs do not contain the `dd.trace_id` and `dd.span_id` attributes required for Datadog to link logs with traces.

## 📊 Findings from Datadog

### ✅ What's Working

**1. APM Traces**
- ✓ Traces are successfully collected
- ✓ Spans show proper hierarchy
- ✓ Service tagging is correct (service:rust-datadog-otel)
- ✓ Error tracking works
- ✓ Performance metrics available
- ✓ Source: `apm` (from OpenTelemetry SDK)

**Example Trace:**
```yaml
span_id: "10876861900508630237"
trace_id: "695103ee00000000b1cf9c8f6c726ec4"
service: rust-datadog-otel
resource: simulate_error
status: error
tags:
  - ingestion_reason:otel
  - env:development
  - version:0.1.0
```

**2. Container Logs**
- ✓ Logs are successfully collected
- ✓ JSON format is parsed correctly
- ✓ Service tagging is correct
- ✓ Log levels (ERROR, INFO, DEBUG) work
- ✓ Source: `rust` (container logs)

**Example Log:**
```yaml
service: rust-datadog-otel
status: error
attributes:
  level: ERROR
  span:
    name: simulate_error
    params: 'ErrorSimulationQuery { error_type: "server" }'
  spans:
    - name: simulate_error
      params: 'ErrorSimulationQuery { error_type: "server" }'
  target: rust_datadog_otel
  threadId: ThreadId(2)
  threadName: tokio-runtime-worker
```

### ❌ What's NOT Working

**Missing Correlation Fields**

The logs **DO NOT** contain:
- ❌ `dd.trace_id` (Datadog trace ID in decimal format)
- ❌ `dd.span_id` (Datadog span ID in decimal format)

**Why This Matters:**

Datadog uses these specific fields to correlate logs with traces. Without them:
- Logs won't show up in trace views
- Traces won't show up in log views  
- No "View Trace" button in logs
- No "Logs" tab in traces
- Cannot navigate between logs and traces

## 🔍 Root Cause Analysis

### Current Log Format

The application outputs span context like this:

```json
{
  "level": "ERROR",
  "timestamp": "2025-12-28T10:19:12.139456Z",
  "span": {
    "name": "simulate_error",
    "params": "ErrorSimulationQuery { error_type: \"server\" }"
  },
  "spans": [
    {
      "name": "simulate_error",
      "params": "ErrorSimulationQuery { error_type: \"server\" }"
    }
  ]
}
```

**Problems:**
1. Span context is in a nested, descriptive format
2. No trace_id or span_id fields at all (even in hex format)
3. Only span names are included, not IDs
4. Format is not recognized by Datadog Agent for correlation

### Expected Format for Correlation

Datadog needs logs in this format:

```json
{
  "level": "ERROR",
  "timestamp": "2025-12-28T10:19:12.139456Z",
  "message": "Simulating error",
  "dd.trace_id": "7621889953578991300",     // ← Required (decimal)
  "dd.span_id": "10876861900508630237",      // ← Required (decimal)
  "dd.service": "rust-datadog-otel",
  "dd.env": "development",
  "dd.version": "0.1.0"
}
```

Or these can be extracted from OpenTelemetry format:

```json
{
  "level": "ERROR",
  "trace_id": "0x695103ee00000000b1cf9c8f6c726ec4",  // OTel hex
  "span_id": "0x970e8e3abfcb39bd"                    // OTel hex
}
```

## 🛠️ Why This Is Happening

### Issue: tracing-opentelemetry Limitation

The `tracing-opentelemetry` crate's current implementation:

```rust
// From src/telemetry.rs
tracing_subscriber::fmt::layer()
    .json()
    .with_current_span(true)     // ← Adds span info
    .with_span_list(true)         // ← Adds span hierarchy
```

**What this does:**
- ✓ Adds span context to logs
- ✓ Includes span names and fields
- ❌ Does NOT include trace_id or span_id
- ❌ Format is not Datadog-compatible

### Why trace_id/span_id Are Missing

The `with_current_span(true)` option includes span metadata (name, fields) but does **NOT** include the OpenTelemetry trace context (trace_id, span_id). This is a known limitation of the `tracing-subscriber` JSON formatter.

## 💡 Possible Solutions

### Option 1: Custom Logging Layer (Recommended)

Create a custom `tracing_subscriber` layer that extracts trace IDs from the OpenTelemetry context and adds them to logs.

**Pros:**
- ✓ Most control over format
- ✓ Can output exactly what Datadog needs
- ✓ Works with existing setup

**Cons:**
- ❌ Requires custom code
- ❌ Maintenance overhead
- ❌ More complexity

**Implementation:**
```rust
// Would need to create a custom layer that:
// 1. Extracts current OTel trace context
// 2. Converts trace_id/span_id to decimal format
// 3. Adds dd.trace_id and dd.span_id to log output
```

### Option 2: Datadog Agent Log Processing

Configure the Datadog Agent to parse OpenTelemetry trace IDs from container logs.

**Current Investigation Needed:**
- Check if Agent can parse nested JSON fields
- Verify Agent configuration for OTel trace ID extraction
- Test custom log pipelines in Datadog

**Pros:**
- ✓ No application code changes
- ✓ Centralized configuration

**Cons:**
- ❌ Requires Agent configuration changes
- ❌ May not work with current log format
- ❌ Need to verify Agent capabilities

### Option 3: Structured Trace ID Logging

Modify the application to explicitly log trace IDs:

```rust
use opentelemetry::trace::TraceContextExt;

#[instrument]
async fn handler() -> impl IntoResponse {
    // Get current span context
    let context = tracing::Span::current().context();
    let span_context = context.span().span_context();
    
    // Log with trace IDs
    info!(
        trace_id = %span_context.trace_id(),
        span_id = %span_context.span_id(),
        "Processing request"
    );
    
    // ... handler logic
}
```

**Pros:**
- ✓ Explicit control over trace ID logging
- ✓ Can format as needed

**Cons:**
- ❌ Requires changes to every handler
- ❌ Repetitive code
- ❌ Easy to forget in new handlers

### Option 4: Use Datadog Logging Library

Use Datadog's logging library alongside OpenTelemetry tracing.

**Pros:**
- ✓ Native Datadog support
- ✓ Automatic correlation

**Cons:**
- ❌ Vendor lock-in
- ❌ Requires additional dependency
- ❌ May not integrate well with tracing ecosystem

## 📋 Recommended Action Plan

### Short Term: Verify Current Behavior

1. ✅ **Confirmed**: Logs do NOT have dd.trace_id/dd.span_id
2. ✅ **Confirmed**: Traces are collected successfully
3. ✅ **Confirmed**: Logs are collected successfully
4. ❌ **Confirmed**: No correlation exists

### Medium Term: Implement Solution

**Recommended: Option 1 (Custom Logging Layer)**

1. Create a custom `tracing_subscriber` layer
2. Extract OpenTelemetry context in the layer
3. Add `dd.trace_id` and `dd.span_id` to log output
4. Convert IDs from hex to decimal format
5. Test correlation in Datadog UI

**Estimated Effort**: 4-8 hours

### Long Term: Monitor and Maintain

1. Test correlation with various log levels
2. Verify correlation across distributed requests
3. Document the implementation
4. Consider contributing back to tracing-opentelemetry

## 🔗 References

### Datadog Documentation
- [Connect Logs and Traces](https://docs.datadoghq.com/tracing/other_telemetry/connect_logs_and_traces/)
- [Rust Tracing](https://docs.datadoghq.com/tracing/trace_collection/custom_instrumentation/rust)
- [Log Management](https://docs.datadoghq.com/logs/)

### Rust Crates
- [tracing-opentelemetry](https://docs.rs/tracing-opentelemetry/)
- [tracing-subscriber](https://docs.rs/tracing-subscriber/)
- [opentelemetry](https://docs.rs/opentelemetry/)

### Related Issues
- [tracing-opentelemetry: Add trace_id to JSON logs](https://github.com/tokio-rs/tracing-opentelemetry/issues/)
- [OpenTelemetry Specification: Trace Context](https://opentelemetry.io/docs/specs/otel/trace/api/#spancontext)

## 📊 Data Summary

### Logs Collected (Last Hour)
- **Count**: 1,237 logs
- **Services**: rust-datadog-otel
- **Environments**: development
- **Hosts**: 2 pods
- **Status**: ✓ Successfully collected
- **Correlation**: ❌ Not correlated

### Traces Collected (Last Hour)
- **Count**: 493 spans
- **Services**: rust-datadog-otel
- **Environments**: development
- **Status**: ✓ Successfully collected
- **Error Tracking**: ✓ Working
- **Correlation**: ❌ Not available for logs

## ✅ Next Steps

1. **Immediate**: Share this analysis with the team
2. **This Week**: Prototype custom logging layer
3. **Next Week**: Test and validate correlation
4. **Following Week**: Roll out to production
5. **Ongoing**: Monitor correlation metrics

---

**Report Generated**: December 28, 2025  
**Data Source**: Datadog MCP Tools  
**Analysis Tool**: Cursor AI Assistant


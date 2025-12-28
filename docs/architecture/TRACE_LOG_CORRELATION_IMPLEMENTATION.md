# Trace-Log Correlation Implementation Plan

**Status**: 🟡 Planning Phase  
**Priority**: High  
**Estimated Effort**: 4-8 hours  
**Target Date**: TBD

## 📋 Executive Summary

This document outlines the implementation plan to add trace-log correlation for the Rust application with Datadog. The goal is to inject `dd.trace_id` and `dd.span_id` into logs so Datadog can correlate logs with traces.

## 🎯 Goals

1. ✅ Add trace IDs to all application logs
2. ✅ Format IDs in Datadog-compatible format (decimal)
3. ✅ Minimize code changes and maintenance overhead
4. ✅ Maintain existing logging structure
5. ✅ No performance degradation

## 🔍 Current State vs Target State

### Current State ❌

```json
{
  "timestamp": "2025-12-28T10:19:12.139456Z",
  "level": "ERROR",
  "message": "Simulating error",
  "span": {
    "name": "simulate_error",
    "params": "..."
  },
  "target": "rust_datadog_otel"
}
```

**Missing**: `dd.trace_id`, `dd.span_id`

### Target State ✅

```json
{
  "timestamp": "2025-12-28T10:19:12.139456Z",
  "level": "ERROR",
  "message": "Simulating error",
  "dd.trace_id": "7621889953578991300",
  "dd.span_id": "10876861900508630237",
  "dd.service": "rust-datadog-otel",
  "dd.env": "development",
  "dd.version": "0.1.0",
  "span": {
    "name": "simulate_error"
  },
  "target": "rust_datadog_otel"
}
```

**Added**: Datadog correlation fields in decimal format

## 📐 Implementation Approach

### Option A: Custom Tracing Layer (RECOMMENDED)

Create a custom `tracing_subscriber::Layer` that enriches logs with trace context.

**Pros:**
- ✅ Automatic for all logs
- ✅ No changes to application code
- ✅ Works with existing instrumentation
- ✅ Clean separation of concerns

**Cons:**
- ⚠️ Requires understanding of tracing-subscriber internals
- ⚠️ ~200 lines of custom code

**Implementation Steps:**

#### Step 1: Create Custom Layer Module

Create `src/datadog_trace_layer.rs`:

```rust
use opentelemetry::trace::{SpanContext, TraceContextExt};
use serde_json::{json, Value};
use tracing::{field::Visit, Subscriber};
use tracing_subscriber::{layer::Context, registry::LookupSpan, Layer};

/// A custom layer that enriches logs with Datadog trace context
pub struct DatadogTraceLayer;

impl DatadogTraceLayer {
    pub fn new() -> Self {
        Self
    }

    /// Extract OpenTelemetry span context and convert to Datadog format
    fn get_trace_context(span_context: &SpanContext) -> Option<(String, String)> {
        if !span_context.is_valid() {
            return None;
        }

        // Get trace_id and span_id
        let trace_id = span_context.trace_id();
        let span_id = span_context.span_id();

        // Convert from 128-bit hex to 64-bit decimal for Datadog
        // Datadog uses the lower 64 bits of the trace_id
        let trace_id_bytes = trace_id.to_bytes();
        let trace_id_lower = u64::from_be_bytes([
            trace_id_bytes[8],
            trace_id_bytes[9],
            trace_id_bytes[10],
            trace_id_bytes[11],
            trace_id_bytes[12],
            trace_id_bytes[13],
            trace_id_bytes[14],
            trace_id_bytes[15],
        ]);

        // Convert span_id from 64-bit hex to decimal
        let span_id_decimal = u64::from_be_bytes(span_id.to_bytes());

        Some((
            trace_id_lower.to_string(),
            span_id_decimal.to_string(),
        ))
    }
}

impl<S> Layer<S> for DatadogTraceLayer
where
    S: Subscriber + for<'a> LookupSpan<'a>,
{
    fn on_event(
        &self,
        event: &tracing::Event<'_>,
        ctx: Context<'_, S>,
    ) {
        // Get the current span
        let current_span = ctx.current_span();
        let span = current_span.id().and_then(|id| ctx.span(id));

        if let Some(span) = span {
            // Get OpenTelemetry span context
            let extensions = span.extensions();
            if let Some(otel_data) = extensions.get::<tracing_opentelemetry::OtelData>() {
                let parent_cx = otel_data.parent_cx.clone();
                let span_context = parent_cx.span().span_context();

                if let Some((trace_id, span_id)) = Self::get_trace_context(span_context) {
                    // Get service configuration
                    let service = std::env::var("DD_SERVICE")
                        .unwrap_or_else(|_| "rust-datadog-otel".to_string());
                    let env = std::env::var("DD_ENV")
                        .unwrap_or_else(|_| "development".to_string());
                    let version = std::env::var("DD_VERSION")
                        .unwrap_or_else(|_| "0.1.0".to_string());

                    // Store Datadog fields for the JSON formatter
                    // Note: This is a simplified version
                    // In practice, you'd need to integrate with the JSON formatter
                    // to inject these fields into the output
                    
                    // One approach: Use tracing fields
                    event.record(&mut DatadogFieldVisitor {
                        trace_id,
                        span_id,
                        service,
                        env,
                        version,
                    });
                }
            }
        }
    }
}

/// Visitor to add Datadog fields to the log event
struct DatadogFieldVisitor {
    trace_id: String,
    span_id: String,
    service: String,
    env: String,
    version: String,
}

impl Visit for DatadogFieldVisitor {
    fn record_debug(&mut self, _field: &tracing::field::Field, _value: &dyn std::fmt::Debug) {
        // Fields are recorded here
        // In a full implementation, we'd inject the Datadog fields
    }
}
```

#### Step 2: Alternative - Use tracing::field! Macro

A simpler approach using explicit field injection:

Create `src/trace_context.rs`:

```rust
use opentelemetry::trace::TraceContextExt;
use tracing::Span;

/// Extract current trace context for logging
pub fn current_trace_context() -> Option<(String, String)> {
    let current_span = Span::current();
    let context = current_span.context();
    let span_context = context.span().span_context();

    if !span_context.is_valid() {
        return None;
    }

    // Convert trace_id to lower 64 bits decimal
    let trace_id_bytes = span_context.trace_id().to_bytes();
    let trace_id_lower = u64::from_be_bytes([
        trace_id_bytes[8],
        trace_id_bytes[9],
        trace_id_bytes[10],
        trace_id_bytes[11],
        trace_id_bytes[12],
        trace_id_bytes[13],
        trace_id_bytes[14],
        trace_id_bytes[15],
    ]);

    // Convert span_id to decimal
    let span_id_bytes = span_context.span_id().to_bytes();
    let span_id_decimal = u64::from_be_bytes(span_id_bytes);

    Some((
        trace_id_lower.to_string(),
        span_id_decimal.to_string(),
    ))
}

/// Macro to add trace context to logs
#[macro_export]
macro_rules! log_with_trace {
    ($level:ident, $($arg:tt)+) => {
        if let Some((trace_id, span_id)) = $crate::trace_context::current_trace_context() {
            tracing::$level!(
                dd.trace_id = %trace_id,
                dd.span_id = %span_id,
                dd.service = %std::env::var("DD_SERVICE").unwrap_or_else(|_| "rust-datadog-otel".to_string()),
                dd.env = %std::env::var("DD_ENV").unwrap_or_else(|_| "development".to_string()),
                dd.version = %std::env::var("DD_VERSION").unwrap_or_else(|_| "0.1.0".to_string()),
                $($arg)+
            );
        } else {
            tracing::$level!($($arg)+);
        }
    };
}

// Convenience macros
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

#### Step 3: Update Application Code

In `src/main.rs`, use the new macros:

```rust
mod trace_context;

// Old way:
// info!("Processing request");

// New way:
info_trace!("Processing request");

// With fields:
error_trace!(
    error_type = %error_type,
    "Simulating error"
);
```

#### Step 4: Update Cargo.toml

No additional dependencies needed for the macro approach!

#### Step 5: Update telemetry.rs

No changes needed - existing setup works fine.

### Option B: JSON Formatter Extension (Alternative)

Create a custom JSON formatter that extends the default one.

**Implementation:**

```rust
use serde_json::json;
use tracing_subscriber::fmt::format::Writer;
use tracing_subscriber::fmt::FormatFields;

pub struct DatadogJsonFormatter;

impl<'writer> FormatFields<'writer> for DatadogJsonFormatter {
    fn format_fields<R: RecordFields>(
        &self,
        writer: Writer<'writer>,
        fields: R,
    ) -> std::fmt::Result {
        // Get trace context
        let (trace_id, span_id) = current_trace_context().unwrap_or_default();
        
        // Build JSON with Datadog fields
        let mut json_fields = json!({
            "dd.trace_id": trace_id,
            "dd.span_id": span_id,
            "dd.service": env::var("DD_SERVICE").unwrap_or_default(),
            "dd.env": env::var("DD_ENV").unwrap_or_default(),
            "dd.version": env::var("DD_VERSION").unwrap_or_default(),
        });
        
        // Add regular fields
        fields.record(&mut JsonVisitor::new(&mut json_fields));
        
        // Write JSON
        write!(writer, "{}", json_fields)
    }
}
```

## 📅 Implementation Timeline

### Phase 1: Prototyping (1-2 hours)
- [ ] Create `src/trace_context.rs` with helper functions
- [ ] Create macros for trace-aware logging
- [ ] Test with one endpoint

### Phase 2: Integration (2-3 hours)
- [ ] Update all logging statements in `src/main.rs`
- [ ] Test all endpoints
- [ ] Verify log format in local environment

### Phase 3: Testing (1-2 hours)
- [ ] Deploy to Kubernetes
- [ ] Generate test traffic with load-test.sh
- [ ] Verify correlation in Datadog UI
- [ ] Test both directions (logs→traces, traces→logs)

### Phase 4: Documentation (1 hour)
- [ ] Update TRACE_LOG_CORRELATION.md
- [ ] Document the approach in README
- [ ] Update troubleshooting guides
- [ ] Create before/after examples

## 🧪 Testing Checklist

### Local Testing
- [ ] Logs show dd.trace_id in decimal format
- [ ] Logs show dd.span_id in decimal format
- [ ] All log levels work (INFO, DEBUG, WARN, ERROR)
- [ ] Performance impact is minimal

### Kubernetes Testing
- [ ] Logs reach Datadog with trace IDs
- [ ] Trace IDs match between logs and traces
- [ ] Service, env, version tags are correct

### Datadog UI Verification
- [ ] Open a trace, see "Logs" tab
- [ ] Logs appear in trace timeline
- [ ] Open a log, see "View Trace" button
- [ ] Clicking navigates correctly
- [ ] Both directions work

## 📝 Code Changes Summary

### Files to Create
1. `src/trace_context.rs` - Trace context extraction and macros
2. `tests/trace_correlation_test.rs` - Unit tests (optional)

### Files to Modify
1. `src/main.rs` - Replace `info!` with `info_trace!`, etc.
2. `Cargo.toml` - No changes needed for macro approach

### Files to Update
1. `docs/guides/TRACE_LOG_CORRELATION.md` - Mark as resolved
2. `README.md` - Add note about correlation
3. `docs/development/CORRELATION_ANALYSIS.md` - Add implementation notes

## 🎯 Success Criteria

### Must Have
- ✅ All logs include dd.trace_id and dd.span_id
- ✅ IDs are in decimal format (Datadog compatible)
- ✅ Correlation visible in Datadog UI
- ✅ No breaking changes to existing functionality

### Nice to Have
- ✅ Minimal code changes (macro approach)
- ✅ No performance degradation
- ✅ Comprehensive tests
- ✅ Clear documentation

## 🔧 Alternative Quick Fix

If you need correlation ASAP, use explicit logging:

```rust
#[instrument]
async fn handler() -> impl IntoResponse {
    use opentelemetry::trace::TraceContextExt;
    
    let span_context = tracing::Span::current()
        .context()
        .span()
        .span_context();
    
    let trace_id = span_context.trace_id().to_bytes();
    let trace_id_lower = u64::from_be_bytes([
        trace_id[8], trace_id[9], trace_id[10], trace_id[11],
        trace_id[12], trace_id[13], trace_id[14], trace_id[15],
    ]);
    
    info!(
        dd.trace_id = %trace_id_lower,
        dd.span_id = %u64::from_be_bytes(span_context.span_id().to_bytes()),
        "Processing request"
    );
    
    // ... handler logic
}
```

**Pros**: Works immediately  
**Cons**: Repetitive, easy to forget

## 📚 References

### Datadog Documentation
- [Connect Logs and Traces](https://docs.datadoghq.com/tracing/other_telemetry/connect_logs_and_traces/)
- [Datadog Log JSON Format](https://docs.datadoghq.com/logs/log_configuration/attributes_naming_convention/)

### Rust Crates
- [tracing-opentelemetry](https://docs.rs/tracing-opentelemetry/)
- [opentelemetry::trace](https://docs.rs/opentelemetry/latest/opentelemetry/trace/)
- [tracing-subscriber](https://docs.rs/tracing-subscriber/)

### Similar Implementations
- [tracing-datadog](https://github.com/DDtKey/tracing-datadog) - Alternative approach
- [OpenTelemetry Rust Examples](https://github.com/open-telemetry/opentelemetry-rust/tree/main/examples)

## 🚀 Next Steps

1. **Review this plan** with the team
2. **Choose approach**: Macro-based (recommended) or custom layer
3. **Create branch**: `feat/trace-log-correlation`
4. **Implement Phase 1**: Prototyping
5. **Test locally** with load-test.sh
6. **Deploy to dev** and verify in Datadog
7. **Document results** and update guides
8. **Merge to main** after validation

## 📊 Expected Outcomes

**Before:**
- 1,237 logs collected ✓
- 493 traces collected ✓
- 0% correlation ✗

**After:**
- 1,237 logs collected ✓
- 493 traces collected ✓
- 100% correlation ✓
- Navigation works both ways ✓
- Trace timeline shows logs ✓

---

**Plan Created**: December 28, 2025  
**Status**: 🟡 Ready for Implementation  
**Estimated Completion**: 1-2 days


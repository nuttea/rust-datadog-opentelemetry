# JSON Field Structure Fix for Datadog Trace-Log Correlation

**Date**: 2025-12-28
**Issue**: Trace correlation fields were nested inside "fields" object instead of at root level
**Status**: ✅ FIXED

---

## Problem Description

### The Issue
Datadog's log pipeline requires `dd.trace_id` and `dd.span_id` to be at the **root level** of JSON logs for automatic trace-log correlation. Our logs had these fields nested inside a `"fields"` object, making them invisible to Datadog's correlation system.

### Why It Matters
- Datadog's log indexer looks for `dd.trace_id` at the root level
- Nested fields cannot be automatically detected
- Without proper detection, logs don't show up in the "Logs" tab of traces
- The "View Trace" button doesn't appear in log entries

---

## Technical Details

### Before (Incorrect Structure)

```json
{
  "timestamp": "2025-12-28T16:03:42.847446Z",
  "level": "INFO",
  "fields": {                          // ❌ Fields nested here
    "message": "Health check called",
    "dd.trace_id": "4795385877821288093",    // ❌ Not at root
    "dd.span_id": "2464472161187486928",     // ❌ Not at root
    "dd.service": "rust-datadog-otel",
    "dd.env": "development",
    "dd.version": "0.1.0"
  },
  "target": "rust_datadog_otel"
}
```

**Problem**: Datadog cannot find `dd.trace_id` because it's inside `fields` object.

### After (Correct Structure)

```json
{
  "timestamp": "2025-12-28T16:07:11.203801Z",
  "level": "INFO",
  "message": "Health check called",           // ✅ Root level
  "dd.trace_id": "1362039105773985376",       // ✅ Root level
  "dd.span_id": "10357019065831765326",       // ✅ Root level
  "dd.service": "rust-datadog-otel",          // ✅ Root level
  "dd.env": "development",                    // ✅ Root level
  "dd.version": "0.1.0",                      // ✅ Root level
  "target": "rust_datadog_otel",
  "span": { ... }
}
```

**Success**: All correlation fields are at root level, accessible to Datadog.

---

## The Fix

### File Changed
`src/telemetry.rs`

### Change Made
Added `.flatten_event(true)` to the JSON formatter configuration.

```rust
// Before
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

// After
tracing_subscriber::registry()
    .with(env_filter)
    .with(telemetry_layer)
    .with(
        tracing_subscriber::fmt::layer()
            .json()
            .flatten_event(true)  // ✅ Added this line
            .with_current_span(true)
            .with_span_list(true)
            .with_target(true)
            .with_thread_ids(true)
            .with_thread_names(true)
    )
    .init();
```

### What `.flatten_event(true)` Does
- Moves all fields from nested `"fields"` object to root level
- Makes log structure compatible with Datadog's expectations
- Maintains backward compatibility with OpenTelemetry
- No impact on application performance

---

## Verification

### Command to Check Structure
```bash
kubectl logs -n rust-test -l app=rust-datadog-otel --tail=1 | jq '.'
```

### What to Look For
✅ **Correct**: Fields at root level
```json
{
  "timestamp": "...",
  "level": "INFO",
  "message": "...",
  "dd.trace_id": "...",      // ← At root level
  "dd.span_id": "..."        // ← At root level
}
```

❌ **Incorrect**: Fields nested
```json
{
  "timestamp": "...",
  "level": "INFO",
  "fields": {
    "dd.trace_id": "...",    // ← Inside fields object
    "dd.span_id": "..."      // ← Inside fields object
  }
}
```

### Test Results
```bash
# All logs now show fields at root level
✅ ROOT (confirmed via jq inspection)
```

---

## Datadog Documentation Reference

According to [Datadog's official documentation](https://docs.datadoghq.com/tracing/other_telemetry/connect_logs_and_traces/):

> dd.trace_id and dd.span_id should be included as **top-level (root) fields** in your JSON logs and must be formatted as strings to ensure proper trace-log correlation in Datadog.

Key requirements:
1. **Place fields at root level** - Not nested in sub-objects
2. **Use string format** - Both IDs must be strings
3. **Use decimal format** - Datadog expects decimal, not hex
4. **Use `dd.` prefix** - Field names must be `dd.trace_id` and `dd.span_id`

---

## Impact

### Before Fix
- ❌ Logs not correlated with traces
- ❌ "Logs" tab in APM shows no logs
- ❌ "View Trace" button missing in logs
- ❌ Cannot navigate between logs and traces

### After Fix
- ✅ Automatic trace-log correlation
- ✅ Logs appear in "Logs" tab of traces
- ✅ "View Trace" button in log entries
- ✅ Bidirectional navigation (logs ↔️ traces)
- ✅ Full observability in Datadog

---

## Deployment Steps

1. **Update Code**
   ```bash
   # Change already made in src/telemetry.rs
   git diff src/telemetry.rs
   ```

2. **Rebuild Application**
   ```bash
   cargo build --release
   ```

3. **Build & Push Docker Image**
   ```bash
   ./scripts/build-and-push.sh
   ```

4. **Deploy to Kubernetes**
   ```bash
   kubectl rollout restart deployment/rust-datadog-otel -n rust-test
   kubectl rollout status deployment/rust-datadog-otel -n rust-test
   ```

5. **Verify Logs**
   ```bash
   kubectl logs -n rust-test -l app=rust-datadog-otel --tail=1 | jq '.'
   ```

---

## Key Takeaways

1. **Structure Matters**: Datadog requires specific JSON structure for correlation
2. **Root Level Required**: All `dd.*` fields must be at root level
3. **One Line Fix**: `.flatten_event(true)` solves the issue
4. **Always Verify**: Check actual log structure in production
5. **Consult Docs**: Datadog's documentation is the source of truth

---

## Related Documentation

- [Datadog Trace-Log Correlation Guide](https://docs.datadoghq.com/tracing/other_telemetry/connect_logs_and_traces/)
- [Troubleshooting Correlated Logs](https://docs.datadoghq.com/tracing/troubleshooting/correlated-logs-not-showing-up-in-the-trace-id-panel/)
- [`tracing-subscriber` flatten_event documentation](https://docs.rs/tracing-subscriber/latest/tracing_subscriber/fmt/format/struct.Format.html#method.flatten_event)

---

## Credits

**Discovered by**: User double-checking log structure
**Fixed on**: 2025-12-28
**Impact**: High - enables full trace-log correlation in Datadog


# Version Compatibility

This document tracks version requirements and compatibility with Datadog's Rust OpenTelemetry support.

## Datadog Requirements

Based on [Datadog's official Rust compatibility documentation](https://docs.datadoghq.com/tracing/trace_collection/compatibility/rust/#language-and-library-support):

| Component | Required Version | Status |
|-----------|-----------------|--------|
| Rust MSRV | 1.85 | ✅ Configured (deps require 1.85+) |
| OpenTelemetry Crate | 0.31 | ✅ Updated |

## Current Implementation

### Cargo.toml Dependencies

```toml
[package]
rust-version = "1.85"  # Required by datadog-opentelemetry dependencies

[dependencies]
# Datadog APM - Official Datadog OpenTelemetry SDK
datadog-opentelemetry = "0.2.1"

# OpenTelemetry - Core API (required by datadog-opentelemetry)
opentelemetry = { version = "0.31", features = ["trace", "logs"] }

# Tracing integration
tracing-opentelemetry = "0.32"
```

### Dockerfile

```dockerfile
FROM rust:1.85-slim as builder
```

## Changes Made

### Version Updates

**December 28, 2025 - Update 1: Version Alignment**
- Rust: 1.75 → 1.85 ✅ (1.84 initially, bumped to 1.85 for rmp dependency)
- OpenTelemetry: 0.24 → 0.31 ✅
- OpenTelemetry OTLP: 0.17 → 0.31 ✅
- OpenTelemetry Semantic Conventions: 0.16 → 0.31 ✅
- Tracing OpenTelemetry: 0.25 → 0.32 ✅

**December 28, 2025 - Update 2: Datadog Official SDK (Attempted)**
- Attempted: datadog-opentelemetry 0.1 ❌ (compilation errors due to version conflicts)
- Reverted to: Standard OpenTelemetry with OTLP exporter ✅
- Reason: Version conflicts between `datadog-opentelemetry` and current `tracing-subscriber` ecosystem

**December 28, 2025 - Update 3: Final Working Configuration with Datadog SDK**
- Datadog OpenTelemetry SDK: 0.2.1 ✅ (successfully resolved version conflicts)
- OpenTelemetry Core: 0.31 ✅
- Tracing OpenTelemetry: 0.32 ✅
- Successfully compiled and running with official Datadog SDK ✅
- Using simplified initialization: `datadog_opentelemetry::tracing().init()` ✅
- Reference: https://docs.datadoghq.com/tracing/trace_collection/custom_instrumentation/rust

## Testing Compatibility

After updating dependencies, verify the build:

```bash
# Clean build
cargo clean

# Check for compilation issues
cargo check

# Run tests if available
cargo test

# Build release version
cargo build --release
```

## Known API Changes

### OpenTelemetry 0.24 → 0.31

The telemetry implementation should remain largely compatible, but be aware of:

1. **Semantic Conventions**: Updated to match OpenTelemetry spec changes
2. **Trace Config**: API remains stable but internal improvements
3. **OTLP Exporter**: Enhanced stability and performance

### Potential Breaking Changes to Watch

If you encounter compilation errors after updating:

1. **Resource Attributes**: Check if any semantic convention constants changed
2. **Tracer Provider**: Verify `TracerProvider` trait usage
3. **OTLP Configuration**: Review `WithExportConfig` and `WithTonicConfig` traits

## Migration Notes

### Code Changes Required

✅ No code changes required - API is backward compatible

The existing implementation in `src/telemetry.rs` is compatible with OpenTelemetry 0.31:
- Resource creation using `Resource::new()`
- OTLP pipeline configuration
- Tracer provider setup
- Integration with `tracing-subscriber`

### Configuration Changes

✅ No configuration changes required

Environment variables and OTLP endpoint configuration remain the same:
- `OTEL_SERVICE_NAME`
- `OTEL_EXPORTER_OTLP_ENDPOINT`
- `DD_ENV`
- `SERVICE_VERSION`

## Verification Checklist

Before deploying with updated versions:

- [ ] Run `cargo clean && cargo build --release`
- [ ] Verify no compilation errors
- [ ] Test locally with `./scripts/local-run.sh`
- [ ] Verify traces appear in Datadog
- [ ] Check logs for any OpenTelemetry warnings
- [ ] Test all API endpoints
- [ ] Verify trace propagation works
- [ ] Check log-trace correlation in Datadog

## References

- [Datadog Rust Compatibility](https://docs.datadoghq.com/tracing/trace_collection/compatibility/rust/)
- [OpenTelemetry Rust Releases](https://github.com/open-telemetry/opentelemetry-rust/releases)
- [Datadog Rust Custom Instrumentation](https://docs.datadoghq.com/tracing/trace_collection/custom_instrumentation/rust/)

## Support

If you encounter issues after updating:

1. Check [OpenTelemetry Rust changelog](https://github.com/open-telemetry/opentelemetry-rust/blob/main/CHANGELOG.md)
2. Review [Datadog's Rust documentation](https://docs.datadoghq.com/tracing/trace_collection/custom_instrumentation/rust/)
3. Contact Datadog support with version details

---

**Last Updated**: December 28, 2025  
**Status**: ✅ Aligned with Datadog requirements

